import "dart:async";
import "dart:math";
import "dart:convert";
import "dart:io";

import "package:polymorphic_bot/api.dart";

BotConnector bot;

void main(List<String> args, Plugin plugin) {
  print("[Script] Loading Plugin");
  bot = plugin.getBot();

  bot.command("eval", (event) {
    File file = new File("/tmp/script${new Random().nextInt(4000)}.dart");

    if (file.existsSync()) {
      file.deleteSync();
    }

    List<String> imports = [
      "dart:async",
      "dart:io",
      "dart:convert",
      "dart:math",
      "dart:mirrors",
      "dart:typed_data",
      "https://gist.githubusercontent.com/kaendfinger/03a43678776d9a906e88/raw/functions.dart"
    ];

    String code = imports.map((it) => "import '${it}';").join("\n") + "\nvoid main() {" + event.args.join(" ") + "}";

    file.writeAsStringSync(code);

    var path = file.absolute.path;

    Process.start("dart", [path]).then((proc) {
      proc.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((data) {
        event.reply("> ${data}");
      });

      proc.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((data) {
        event.replyNotice("> ${data}");
      });

      new Timer(new Duration(seconds: 5), () {
        if (proc.kill()) {
          event.reply("> Script was killed (over 5 seconds of execution time)");
        }

        file.deleteSync();
      });
    });
  }, permission: "eval");

  bot.command("js-eval", (event) {
    File file = new File("/tmp/script${new Random().nextInt(4000)}.js");

    file.writeAsStringSync(event.args.join(" "));

    var path = file.absolute.path;

    Process.start("node", [path]).then((proc) {
      proc.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((data) {
        event.reply("> ${data}");
      });

      proc.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((data) {
        event.replyNotice("> ${data}");
      });

      new Timer(new Duration(seconds: 5), () {
        if (proc.kill()) {
          event.reply("> Script was killed (over 5 seconds of execution time)");
        }

        file.deleteSync();
      });
    });
  }, permission: "js-eval");
}
