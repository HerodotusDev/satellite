import readline from "readline";

interface Option {
  label: string;
  selected?: boolean;
  switchable: boolean | null;
}

export class ConsoleMenu {
  private options: Option[];
  private cursor = 0;

  constructor(options: Option[]) {
    this.options = options;
    while (this.options[this.cursor].switchable !== true) {
      if (this.cursor + 1 === this.options.length) {
        break;
      }
      this.cursor++;
    }
  }

  async show(): Promise<Option[]> {
    return new Promise((resolve) => {
      this.setupInput(resolve);
      this.render();
    });
  }

  private setupInput(resolve: (options: Option[]) => void) {
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) process.stdin.setRawMode(true);

    process.stdin.on("keypress", (_, key) => {
      if (key.name === "up") {
        // TODO: infinite loop?
        do {
          this.cursor =
            (this.cursor - 1 + this.options.length) % this.options.length;
        } while (this.options[this.cursor].switchable !== true);
      } else if (key.name === "down") {
        // TODO: infinite loop?
        do {
          this.cursor = (this.cursor + 1) % this.options.length;
        } while (this.options[this.cursor].switchable !== true);
      } else if (key.name === "space") {
        const option = this.options[this.cursor];
        if (option.switchable) option.selected = !option.selected;
      } else if (key.name === "return") {
        this.finish(resolve);
        return;
      } else if (key.name === "c" && key.ctrl) {
        this.exit();
      }

      this.render();
    });
  }

  private render() {
    console.clear();
    console.log("Use arrow keys to move, space to select, enter to finish\n");

    this.options.forEach((option, idx) => {
      const cursor = idx === this.cursor ? ">" : " ";
      if (option.switchable === null) {
        console.log(`${cursor}${option.label}`);
        return;
      }
      const checkBox =
        option.switchable === true
          ? option.selected
            ? "[x]"
            : "[ ]"
          : option.selected
            ? "(x)"
            : "( )";
      console.log(`${cursor} ${checkBox} ${option.label}`);
    });
  }

  private finish(resolve: (options: Option[]) => void) {
    process.stdin.setRawMode(false);
    process.stdin.removeAllListeners("keypress");
    console.clear();
    resolve(this.options);
  }

  private exit() {
    process.stdin.setRawMode(false);
    process.stdin.removeAllListeners("keypress");
    console.clear();
    process.exit();
  }
}
