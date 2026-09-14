# Exemplo do Markee

Aplicativo Flutter com uma única tela para editar Markdown usando a barra de
ferramentas e os atalhos do Markee. O conteúdo fica em memória durante a execução.

O exemplo usa o pacote deste repositório por meio de `path: ..`. Em
[`lib/main.dart`](lib/main.dart), um `MarkdownEditingController` fornece o texto
inicial ao `MarkdownEditor` e é descartado quando a tela é removida. O Markdown
editado pode ser acessado por `controller.text`.

## Executar

Na raiz do repositório:

```sh
cd example
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

Os projetos de Android, iOS, web, Windows, macOS e Linux estão incluídos. Use o
ambiente de desenvolvimento e as ferramentas necessárias para a plataforma de
destino; iOS e macOS exigem macOS, Windows exige Windows e Linux exige Linux.
Para executar em um dispositivo iOS físico, selecione sua equipe de assinatura
no Xcode em `ios/Runner.xcworkspace`.

Exemplos:

```sh
flutter run -d chrome
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

Para Android e iOS, use o identificador do emulador, simulador ou dispositivo
listado por `flutter devices`.

## Verificar

Dentro de `example/`:

```sh
flutter analyze
flutter test
```
