# FAIT AGÊNCY — editor multiplataforma

Nome do aplicativo: **FAIT AGÊNCY**  
Assinatura: **FAIT AGÊNCY & TODDY CEO!**  
Alvo: Android (APK), iOS e Windows.  
Tecnologia: Flutter/Dart.

## Implementado nesta base
- Interface moderna em azul/ciano e tema escuro.
- Área de trabalho quadrada com grade de transparência.
- Importação de imagem da galeria (plugin `image_picker`).
- Camadas de imagem, texto, forma e fundo.
- Adicionar texto por diálogo.
- Adicionar forma básica.
- Selecionar, ocultar e reordenar camadas.
- Duplicar e excluir camada.
- Propriedades de opacidade e tamanho do texto.
- Histórico inicial de desfazer/refazer para operações estruturais.
- Pré-visualização simples de sombra 3D em textos/formas.
- Layout adaptável a telas estreitas e largas.

## Ainda não implementado
- Pincel/borracha com desenho real no canvas.
- Transformação livre por toque (mover, girar, redimensionar objetos).
- Efeitos 3D avançados e filtros.
- Remoção automática de fundo (precisa de modelo/serviço de segmentação).
- Importação/exportação PSD real e preservação de recursos PSD.
- Exportação raster PNG/JPG do canvas composto.
- Salvamento e abertura de projetos nativos.
- Histórico completo de cada alteração e testes de desempenho.

## Executar
Instale Flutter SDK. Extraia o ZIP e rode:

```bash
flutter pub get
flutter run
```

## Compilar
```bash
flutter build apk
flutter build windows
flutter build ios
```

Android pode gerar APK em ambiente com Android SDK. Windows precisa ser compilado no Windows com Visual Studio Build Tools. iOS precisa de macOS e Xcode. O ZIP é código-fonte, não um APK compilado.
