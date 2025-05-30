import { App, Gtk } from "astal/gtk4";
import { bash, cn } from "../../lib/utils";

export interface QuickResultPlugin {
  name: string;
  test: (input: string) => boolean;
  execute: (input: string) => Promise<QuickResult | null> | QuickResult | null;
}

export interface QuickResult {
  display: string | Gtk.Widget;
  clipboardValue: string;
}

export class QuickResultsManager {
  private plugins: QuickResultPlugin[] = [];

  addPlugin(plugin: QuickResultPlugin) {
    this.plugins.push(plugin);
  }

  async processInput(input: string): Promise<QuickResult | null> {
    for (const plugin of this.plugins) {
      if (plugin.test(input)) {
        try {
          return await plugin.execute(input);
        } catch (error) {
          console.warn(`Plugin ${plugin.name} failed:`, error);
          continue;
        }
      }
    }
    return null;
  }
}

// Calculator Plugin
export const calculatorPlugin: QuickResultPlugin = {
  name: "calculator",
  test: (input: string) => /.*\d+.*/.test(input),
  execute: (input: string) => {
    try {
      const result = bash(`echo "scale=2; ${input}" | bc -l`);
      return {
        display: result,
        clipboardValue: result,
      };
    } catch {
      return null;
    }
  },
};

// Color Converter Plugin
export const colorConverterPlugin: QuickResultPlugin = {
  name: "colorConverter",
  test: (input: string) => /^(#|rgb|hsl|okl)/.test(input),
  execute: (input: string) => {
    const words = input.split(" to ");
    const color = words.at(0);
    const variant = words.at(1);

    if (!color || !variant) return null;

    try {
      const result = bash(`echo "${color}" | pastel format ${variant}`);
      return {
        display: (
          <box>
            <label cssClasses={cn("text-fg/50")}>{result}</label>
            <box
              name="__color_preview"
              cssClasses={cn("rounded min-w-2 min-h-2")}
              setup={() => {
                const css = `#__color_preview{background-color:${result};}`;
                App.apply_css(css);
              }}
            />
          </box>
        ),
        clipboardValue: result,
      };
    } catch {
      return null;
    }
  },
};
