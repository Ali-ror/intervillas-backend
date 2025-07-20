# ModelForm

*(Gem für den internen Gebrauch)*

Eine naive Form-Objekt-Implementierung, nicht unähnlich zu [Reform][reform-gh],
nur sehr viel weniger komplex. Aus Intervillas extrahiert.

[reform-gh]: https://github.com/apotonick/reform


## Installation

Ins `Gemfile`:

```ruby
gem "model-form", git: "git@git.digineo.de:plugins/model_form"
```

Dann:

```
$ bundle
$ mkdir -p app/forms
```

## How-To

Form-Objekt von `ModelForm` ableiten (`app/forms/user_form.rb`):

```ruby
class UserForm < ModelForm
  from_model :user

  attribute :email, String
  validates :email,
    presence:     true,
    email_format: true
end
```

Im Controller die Resource wrappen (`app/controllers/users_controller.rb`):

```ruby
class UsersController < ApplicationController
  helper_method :user_form

private

  def user
    @user ||= User.find params[:id]
  end

  def user_form
    @user_form ||= UserForm.from_user user
  end
end
```

Im View anstelle von `form_for @user` (`app/views/users/edit.html.haml`):

```haml
= form_for user_form do |f|
  = f.label :email
  = f.email_field :email
  %br
  = f.submit
```

Und schließlich in der `#update`-Methode (wieder `app/controllers/users_controller.rb`)
erst Parameter mit `#valid?` prüfen und dann mit `#save` speichern:

```ruby
def update
  user_form.attributes = params[:user]
  if user_form.valid?
    user_form.save
    redirect_to users_path, notice: "Benutzer gespeichert."
  else
    render action: :edit
  end
end
```


# Doku

```ruby
class UserForm < ModelForm
  from_model :user
end
```

`::from_model(model_sym, destroyable: false)` erwartet ein Symbol, das (via
`#classify`) zu einem `ActiveRecord`- oder `ActiveModel`-Model aufgelöst werden
kann (hier `:user` → `User`).

Wenn `destroyable` zu *wahr* evaluiert, verhält sich das ganze Form-Objekt wie
ein End-Glied in einer `nested_attributes`-Kette.

Diese Methode deklariert eine `from_user`-Factory-Klassenmethode, die als
Argument eine User-Instanz erwartet, aus dem es die benötigten Attribute laden
kann.

Diese Attribute gliedern sich in "tatsächliche" Attribute, die in
`user.attributes` zu finden sind, und "virtuelle Attribute", die eine
User-Methode auf ein Virtus-`attribute` mappen.

Im folgenden Beispiel sei `email` ein Datenbank-Feld und `password` ein
virtuelles Feld (nur Setter, kein Getter):

```ruby
class User < ActiveRecord::Base
  def password=(pw)
    self.encrypted_password = Devise.encrypt_password(pw)
  end
end

class UserForm < ModelForm
  from_model :user

  attribute :email
  validates :email, presence: true, email_format: true

  attribute :password
  validates :password, presence: true, confirmation: true
end

uf = UserForm.from_user User.first
#=> #<UserForm:0x1234
#   @email="user@example.com",
#   @password=nil,
#   @user=#<User:0x0101
#     id: 1,
#     email: "user@example.com",
#     encrypted_password: "$2a$10$e1Aesk...",
#     ...>
#   >

uf.attributes = { password: "foo", password_confirmation: "foo" } #=> #<Hash>
uf.valid? #=> true
uf.save
#   UPDATE users SET encrypted_password = '$2a$10$3n4uLs...' WHERE id = 1
#=> true

# Shortcut: set attributes and call #valid?
uf.process(password: "foo", password_confirmation: "foo") #=> true
uf.save
#   UPDATE users SET encrypted_password = '$2a$10$3nlaUa...' WHERE id = 1
#=> true


User.first
#=> #<User:0x0101
#   id: 1,
#   email: "user@example.com",
#   encrypted_password: "$2a$10$3n4uLs...",
#   ...>
```


Das Laden der Attribut-Werte erfolgt nach einem naiven Ansatz:

1. Kopiere alle Attribute, die in `self.attributes` deklariert sind, aus
   aus `model.attributes`, sofern diese in `model` existieren und nicht `nil`
   sind.
2. Rufe `self.init_virtual` auf und kopiere die Attribute, die in `self.attributes`
   deklariert sind, und die als Methoden in `model` existieren.

Insbesondere bei komplexeren Form-Objekten, die nicht nur ein einziges Objekt
zur Grundlage haben schlägt dies allerdings fehl, und das Verhalten muss
(durch Überschreiben der `#init_virtual`-Methode) angepasst werden. Ob `super`
aufgerufen werden kann, muss im Einzelfall entschieden werden.

```ruby
class UserForm < ModelForm
  from_model :user

  delegate :inquiry, to: :user # angenommen, User.belongs_to(:inquiry)
  attribute :comment, String

  def init_virtual
    self.comment = inquiry.comment if persisted?
  end
end
```

Wenn `#init_virtual` überschrieben wird, muss sehr wahrscheinlich auch `#save`
angepasst werden:

```ruby
class UserForm < ModelForm
  #...

  def save
    inquiry.comment = comment
    inquiry.save!
    super
  end
end
```
