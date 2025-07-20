# `Exposer` und `Memoizable`

Führt zwei Metaprogramming-Methoden ein:

- `memoize` (general purpose method caching)
- `expose` (ActionController-glue code)

Sinn und Zweck dieser Methoden ist es, typischen Boilerplate-Code zum Cachen
von (Zwischen-) Ergebnissen loszuwerden (nicht ganz unähnlich zu RSpecs `let`):

    # vorher
    class User
      def foo
        @foo ||= begin
          # really complex, expensive code
          sleep 2
          42
        end
      end

      private

      def bar
        @bar ||= foo
      end
    end

    # nachher
    class User
      include Memoizable

      memoize :foo do
        sleep 2
        42
      end

      memoize(:bar, true) { foo }
    end

Das ganze ist einem Hack von Timo entwachsen, der typische Rails-Controller
entschlackt hat:

    # vorher
    class FooController < ApplicationController
      helper_method :make_foo

      private

      def make_foo
        @foo_made ||= compute_something!
      end
    end

    # nachher
    class FooController < ApplicationController
      include Exposer

      expose(:make_foo) { compute_something! }
    end

(letzteres funktioniert weiterhin, sofern die `FooController`-Klasse eine
Methode `#helper_method` definiert)

## Installation

    gem "digineo_exposer", git: "git@git.digineo.de:plugins/exposer"

ins `Gemfile` und `bundle` aufrufen.

## API

### `memoize(name, options={}, &code)`

- **`name`**:
  Name der Methode, die erzeugt wird (Signatur: `name(reload=false)`). Beim ersten
  Aufruf wird das Ergebnis vom `code`-Block in einer Instanzvariable mit Namen
  `@name` gecacht.
- **`options[:nil]`**:
  Gibt an, ob `nil` ein gültiges Ergebnis darstellt (Default: `true`).
- **`options[:private]`**:
  Gibt an, ob die erzeugte Method `private` Sichtbarkeit bekommen soll
  (Default: `false`).
- **`&code`**:
  Code-Block für den Methoden-Rumpf.

### `expose(name, before: [:list, :of, :actions], &code)`

Kurz für:

    memoize(name, private: true, nil: false, &code)
    helper_method name

Wenn `before` gesetzt ist, wird eine `before_action` mit den übergebenen Values
als Whitelist erzeugt:

    before_action name, only: [:list, :of, :actions]

# FAQ

## `undefined method 'helper_method' for Foo:Class`

Du hast `expose` ausserhalb einer Rails-Anwendung benutzt. Böse, böse!

- Ersetze `include Exposer` mit `include Momoizable` und `expose` mit `memoize`.
- Oder hacke dir eine `Foo.helper_method` zusammen.
