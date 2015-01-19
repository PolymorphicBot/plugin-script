import "dart:async";
import "dart:math";
import "dart:convert";
import "dart:io";

import "package:which/which.dart";
import "package:polymorphic_bot/api.dart";
import "package:compiler_unsupported/src/dart2js.dart";

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
    
    var input = event.args.join(" ");
    String code;
    
    if (input.length > 1 && input[0] == "@") {
      input = input.substring(1);
      code = input;
    } else {
      code = imports.map((it) => "import '${it}';").join("\n") + "\nvoid main() {" + event.args.join(" ") + "}";
    }

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
  
  bot.command("eval-dart2js", (event) {    
    var cmd = whichSync("dart", orElse: () => "${Platform.environment["HOME"]}/Development/Tools/dart/bleeding_edge/sdk/bin/dart");
    var sdkDir = new File(cmd).parent.parent;
    
    if (sdkDir.path.startsWith("/usr/lib")) {
      sdkDir = new Directory("/opt/dart-sdk");
    }

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
    
    var mydir = new File.fromUri(Platform.script).parent;
    var preamble = new File("${mydir.path}/preamble.js");
    
    var input = event.args.join(" ");
    String code;
    
    if (input.length > 1 && input[0] == "@") {
      input = input.substring(1);
      code = input;
    } else {
      code = imports.map((it) => "import '${it}';").join("\n") + "\nvoid main() {" + event.args.join(" ") + "}";
    }
    
    var tmpDir = Directory.systemTemp.createTempSync("eval-dart2js");
    var out = new File("${tmpDir.path}/out.js");
    
    file.writeAsStringSync(code);
    
    compilerMain(["--categories=Server", "--library-root=${sdkDir.path}", "-o", out.path, file.path]).then((result) {
      if (!result.isSuccess) {
        event.reply("> Compilation Failed!");
        file.deleteSync();
        tmpDir.deleteSync(recursive: true);
        return null;
      }
      
      out.writeAsStringSync(preamble.readAsStringSync() + "\n" + out.readAsStringSync());
      
      return Process.start("node", [out.path]);
    }).then((proc) {
      if (proc == null) {
        return;
      }
      
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
        tmpDir.deleteSync(recursive: true);
      });
    }).catchError((e) {
      print(e);
      event.reply("> Compilation Failed! Check Bot Console.");
      
      file.deleteSync();
      tmpDir.deleteSync(recursive: true);
    });
  }, permission: "eval-dart2js");

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
