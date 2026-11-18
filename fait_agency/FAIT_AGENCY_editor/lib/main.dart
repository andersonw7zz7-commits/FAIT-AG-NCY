import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const FaitAgencyApp());

const brandBlue = Color(0xFF087ED5);
const cyan = Color(0xFF00D5E8);
const page = Color(0xFF0B1420);
const panel = Color(0xFF111F2E);

class FaitAgencyApp extends StatelessWidget {
  const FaitAgencyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FAIT AGÊNCY',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: page,
      colorScheme: ColorScheme.fromSeed(seedColor: brandBlue, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const EditorHome(),
  );
}

enum LayerKind { background, image, text, shape }

class EditorLayer {
  EditorLayer({
    required this.id,
    required this.name,
    required this.kind,
    this.text = '',
    this.imagePath,
    this.visible = true,
    this.opacity = 1,
    this.fontSize = 42,
    this.color = Colors.white,
  });

  final int id;
  String name;
  final LayerKind kind;
  String text;
  String? imagePath;
  bool visible;
  double opacity;
  double fontSize;
  Color color;

  EditorLayer copy() => EditorLayer(
    id: id, name: name, kind: kind, text: text, imagePath: imagePath,
    visible: visible, opacity: opacity, fontSize: fontSize, color: color,
  );
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});
  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  final picker = ImagePicker();
  final List<EditorLayer> layers = [];
  final List<List<EditorLayer>> undoStack = [];
  final List<List<EditorLayer>> redoStack = [];
  int nextId = 1;
  int? selectedId;
  String activeTool = 'Mover';
  bool showLayers = true;
  bool show3d = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    layers.add(EditorLayer(id: nextId++, name: 'Fundo', kind: LayerKind.background, color: const Color(0xFF087ED5)));
    selectedId = layers.first.id;
  }

  EditorLayer? get selected {
    for (final layer in layers) {
      if (layer.id == selectedId) return layer;
    }
    return null;
  }

  void checkpoint() {
    undoStack.add(layers.map((e) => e.copy()).toList());
    if (undoStack.length > 40) undoStack.removeAt(0);
    redoStack.clear();
  }

  void undo() {
    if (undoStack.isEmpty) return;
    redoStack.add(layers.map((e) => e.copy()).toList());
    setState(() {
      layers
        ..clear()
        ..addAll(undoStack.removeLast().map((e) => e.copy()));
      selectedId = layers.isEmpty ? null : layers.last.id;
    });
  }

  void redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(layers.map((e) => e.copy()).toList());
    setState(() {
      layers
        ..clear()
        ..addAll(redoStack.removeLast().map((e) => e.copy()));
      selectedId = layers.isEmpty ? null : layers.last.id;
    });
  }

  void addText() {
    final controller = TextEditingController(text: 'Seu texto');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar texto'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Digite seu texto')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              checkpoint();
              setState(() {
                final item = EditorLayer(id: nextId++, name: 'Texto', kind: LayerKind.text, text: controller.text.trim());
                layers.add(item);
                selectedId = item.id;
              });
            }
            Navigator.pop(ctx);
          }, child: const Text('Adicionar')),
        ],
      ),
    );
  }

  Future<void> importImage() async {
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (file == null) return;
      checkpoint();
      setState(() {
        final item = EditorLayer(id: nextId++, name: 'Imagem ${layers.where((e) => e.kind == LayerKind.image).length + 1}', kind: LayerKind.image, imagePath: file.path);
        layers.add(item);
        selectedId = item.id;
      });
    } catch (e) {
      notify('Não foi possível abrir a galeria: $e');
    }
  }

  void addShape() {
    checkpoint();
    setState(() {
      final item = EditorLayer(id: nextId++, name: 'Forma', kind: LayerKind.shape, color: cyan);
      layers.add(item);
      selectedId = item.id;
    });
  }

  void duplicateSelected() {
    final current = selected;
    if (current == null) return;
    checkpoint();
    setState(() {
      final copy = current.copy()
        ..name = '${current.name} cópia';
      final clone = EditorLayer(id: nextId++, name: copy.name, kind: copy.kind,
        text: copy.text, imagePath: copy.imagePath, visible: copy.visible,
        opacity: copy.opacity, fontSize: copy.fontSize, color: copy.color);
      layers.add(clone);
      selectedId = clone.id;
    });
  }

  void deleteSelected() {
    if (selected == null || selected!.kind == LayerKind.background) return;
    checkpoint();
    setState(() {
      layers.removeWhere((e) => e.id == selectedId);
      selectedId = layers.isEmpty ? null : layers.last.id;
    });
  }

  void notify(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void tool(String name) {
    setState(() => activeTool = name);
    switch (name) {
      case 'Texto': addText(); break;
      case 'Imagem': importImage(); break;
      case 'Forma': addShape(); break;
      case 'Camadas': setState(() => showLayers = !showLayers); break;
      case 'Efeito 3D':
        checkpoint();
        setState(() => show3d = !show3d);
        notify(show3d ? 'Pré-visualização de sombra 3D ativada.' : 'Efeito 3D desativado.');
        break;
      case 'Remover fundo':
        notify('A ferramenta de remoção automática de fundo será conectada a um serviço de processamento na próxima etapa.');
        break;
      case 'PSD':
        notify('Salvar e abrir PSD exige implementar o conversor de camadas/compatibilidade PSD. Ainda não está ativo.');
        break;
      case 'Pincel':
      case 'Borracha':
      case 'Recorte':
        notify('$name: ferramenta planejada; ainda não está conectada ao canvas.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2236),
        titleSpacing: 12,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FAIT AGÊNCY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          Text('FAIT AGÊNCY & TODDY CEO!', style: TextStyle(fontSize: 10, color: cyan)),
        ]),
        actions: [
          IconButton(tooltip: 'Desfazer', onPressed: undoStack.isEmpty ? null : undo, icon: const Icon(Icons.undo)),
          IconButton(tooltip: 'Refazer', onPressed: redoStack.isEmpty ? null : redo, icon: const Icon(Icons.redo)),
          IconButton(tooltip: 'Duplicar camada', onPressed: duplicateSelected, icon: const Icon(Icons.copy_all_outlined)),
          IconButton(tooltip: 'Exportar', onPressed: () => notify('Exportação PNG/JPG será implementada após o motor de composição.'), icon: const Icon(Icons.file_download_outlined)),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(children: [
        _documentBar(),
        Expanded(child: Row(children: [
          _toolsRail(),
          Expanded(child: _canvas()),
          if (wide && showLayers) SizedBox(width: 245, child: _layersPanel()),
        ])),
        if (!wide && showLayers) SizedBox(height: 126, child: _layersPanel(compact: true)),
        _statusBar(),
      ]),
    );
  }

  Widget _documentBar() => Container(
    height: 38, color: const Color(0xFF14283B), padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(children: [
      const Icon(Icons.insert_drive_file_outlined, size: 16, color: cyan),
      const SizedBox(width: 8),
      const Text('Projeto sem título', style: TextStyle(fontSize: 11)),
      const Spacer(),
      const Text('1080 × 1080 px', style: TextStyle(fontSize: 10, color: Colors.white60)),
      const SizedBox(width: 8),
      const Icon(Icons.more_horiz, size: 18),
    ]),
  );

  Widget _toolsRail() {
    final entries = <(String, IconData)>[
      ('Mover', Icons.open_with), ('Texto', Icons.title), ('Imagem', Icons.image_outlined),
      ('Pincel', Icons.brush), ('Borracha', Icons.auto_fix_off), ('Recorte', Icons.crop),
      ('Forma', Icons.crop_square), ('Camadas', Icons.layers_outlined),
      ('Efeito 3D', Icons.view_in_ar), ('Remover fundo', Icons.auto_fix_high), ('PSD', Icons.layers),
    ];
    return Container(
      width: 58, color: panel,
      child: ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: entries.map((e) {
        final active = activeTool == e.$1;
        return Tooltip(message: e.$1, child: InkWell(
          onTap: () => tool(e.$1),
          child: Container(
            height: 43, margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: active ? brandBlue.withOpacity(.28) : Colors.transparent,
              borderRadius: BorderRadius.circular(9), border: active ? Border.all(color: cyan.withOpacity(.7)) : null),
            child: Icon(e.$2, color: active ? cyan : Colors.white70, size: 20),
          ),
        ));
      }).toList()),
    );
  }

  Widget _canvas() => Container(
    color: const Color(0xFF202B37), alignment: Alignment.center, padding: const EdgeInsets.all(16),
    child: AspectRatio(aspectRatio: 1, child: ClipRect(
      child: Container(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))]),
        child: Stack(fit: StackFit.expand, children: [
          CustomPaint(painter: TransparencyGrid()),
          for (final layer in layers.where((e) => e.visible))
            if (layer.kind == LayerKind.background)
              ColoredBox(color: layer.color.withOpacity(layer.opacity))
            else if (layer.kind == LayerKind.image && layer.imagePath != null)
              Opacity(opacity: layer.opacity, child: Image.file(File(layer.imagePath!), fit: BoxFit.contain))
            else if (layer.kind == LayerKind.text)
              Center(child: Opacity(opacity: layer.opacity, child: Text(layer.text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: layer.fontSize, color: layer.color, fontWeight: FontWeight.w900,
                  shadows: show3d ? const [Shadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 6)), Shadow(color: cyan, blurRadius: 12)] : const [])))),
            else if (layer.kind == LayerKind.shape)
              Center(child: Opacity(opacity: layer.opacity, child: Container(width: 130, height: 130,
                decoration: BoxDecoration(color: layer.color, borderRadius: BorderRadius.circular(18),
                  boxShadow: show3d ? const [BoxShadow(color: Colors.black87, blurRadius: 0, offset: Offset(8, 9))] : null)))),
          if (layers.length == 1)
            const Center(child: Text('Importe uma imagem ou adicione texto', style: TextStyle(color: Colors.white70, fontSize: 12))),
        ]),
      ),
    )),
  );

  Widget _layersPanel({bool compact = false}) => Container(
    color: panel, padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.layers, size: 16, color: cyan),
        const SizedBox(width: 7),
        const Text('CAMADAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const Spacer(),
        IconButton(visualDensity: VisualDensity.compact, onPressed: () => tool('Forma'), icon: const Icon(Icons.add, size: 18)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: deleteSelected, icon: const Icon(Icons.delete_outline, size: 18)),
      ]),
      Expanded(child: compact
        ? ListView(scrollDirection: Axis.horizontal, children: layers.map((e) => _layerTile(e, horizontal: true)).toList())
        : ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              checkpoint();
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = layers.removeAt(oldIndex);
                layers.insert(newIndex, item);
              });
            },
            children: layers.map((e) => _layerTile(e, key: ValueKey(e.id))).toList(),
          )),
      if (!compact && selected != null) _properties(),
    ]),
  );

  Widget _layerTile(EditorLayer layer, {bool horizontal = false, Key? key}) {
    final active = layer.id == selectedId;
    return Container(
      key: key,
      width: horizontal ? 150 : null,
      margin: const EdgeInsets.only(bottom: 4, right: horizontal ? 5 : 0),
      decoration: BoxDecoration(color: active ? brandBlue.withOpacity(.25) : Colors.white.withOpacity(.035),
        borderRadius: BorderRadius.circular(7), border: active ? Border.all(color: brandBlue) : null),
      child: Row(children: [
        if (!horizontal) const Icon(Icons.drag_indicator, size: 15, color: Colors.white38),
        Expanded(child: InkWell(onTap: () => setState(() => selectedId = layer.id),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
            child: Row(children: [
              Icon(layer.kind == LayerKind.text ? Icons.title : layer.kind == LayerKind.image ? Icons.image : Icons.layers,
                size: 15, color: cyan),
              const SizedBox(width: 6),
              Expanded(child: Text(layer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
            ]),
          ))),
        IconButton(visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 27, height: 27),
          onPressed: () => setState(() => layer.visible = !layer.visible),
          icon: Icon(layer.visible ? Icons.visibility : Icons.visibility_off, size: 14, color: Colors.white60)),
      ]),
    );
  }

  Widget _properties() {
    final layer = selected!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(color: Colors.white12),
      const Text('PROPRIEDADES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cyan)),
      Row(children: [
        const Text('Opacidade', style: TextStyle(fontSize: 10)),
        Expanded(child: Slider(value: layer.opacity, onChanged: (v) => setState(() => layer.opacity = v))),
        Text('${(layer.opacity * 100).round()}%', style: const TextStyle(fontSize: 10)),
      ]),
      if (layer.kind == LayerKind.text)
        Row(children: [
          const Text('Tamanho', style: TextStyle(fontSize: 10)),
          Expanded(child: Slider(min: 12, max: 100, value: layer.fontSize, onChanged: (v) => setState(() => layer.fontSize = v))),
        ]),
    ]);
  }

  Widget _statusBar() => Container(
    height: 30, color: const Color(0xFF0D2236), padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(children: [
      const Text('FAIT AGÊNCY • BETA', style: TextStyle(fontSize: 9, color: cyan)),
      const Spacer(),
      Text('${layers.length} camada(s)  •  $activeTool', style: const TextStyle(fontSize: 9, color: Colors.white54)),
    ]),
  );
}

class TransparencyGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 18.0;
    final light = Paint()..color = const Color(0xFF46515D);
    final darkPaint = Paint()..color = const Color(0xFF333E49);
    for (var y = 0; y < size.height; y += 18) {
      for (var x = 0; x < size.width; x += 18) {
        final even = ((x ~/ 18) + (y ~/ 18)) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), cell, cell), even ? light : darkPaint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
