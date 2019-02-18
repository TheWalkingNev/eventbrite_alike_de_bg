# Path to follow BG version

# Eventbrite Alike de BG
---
## Création et mise en place de l'application
1. `rails new -d postgresql nom_de_l_application`
2. ajouter les gems de tests au Gemfile  
      `gem 'rspec-rails'`                 development, test ( ~ ligne 40 )  
      `gem 'factory_bot_rails'`           development, test ( ~ ligne 40 )  
      `gem 'faker'`                       development, test ( ~ ligne 40 )  
      `gem 'shoulda-matchers'`            test ( ~ ligne 60 après l'insertion des 3 gems précédentes )  
      `gem 'rails-controller-testing'`    test ( ~ ligne 60 après l'insertion des 3 gems précédentes )  
      `gem 'nyan-cat-formatter'`          test ( ~ ligne 60 après l'insertion des 3 gems précédentes )
3. `bundle install`
4. `rails g rspec:install`
5. sur ./spec/rails_helper.rb, commenter la ligne 40  
( `config.use_transactional_fixtures = true` )  
et ajouter  
( `config.include FactoryBot::Syntax::Methods` )  
à la ligne suivante
6. ajouter à la fin du même fichier :  
`Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end`
7. ajouter sur .rspec `--format NyanCatFormatter`
8. ajouter la `gem 'devise'` et la `gem 'table_print'` sur le Gemfile
9. `bundle install`
10. `rails generate devise:install`
11. ajouter sur ./config/environments/development.rb  
`config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }`  
( sous la ligne 36 qui parle également des mailer semble être un bon choix )

---
## Création des models et de quelques tests

12. `rails g devise user`
13. `rails db:create`
14. `rails db:migrate`
15. `rails g migration AddSomeAttributesToUser` ( ou peu importe le nom que tu veux donner à la migration du moment que c'est claire pour toi )
16. dans cette migration, ajouter dans la def change :  
`change_table :users do |t|
  t.string :first_name
  t.string :last_name
  t.text :description
end`  
( la table users a était créée par 'devise' on a donc juste a lui rajouter les attributs manquants )
17. `rails db:migrate`
18. dans ./spec/factories/users.rb, ajouter :  
`email { Faker::Internet.email }
password { Faker::Internet.password }`
19. dans ./spec/models/user_spec.rb, ajouter :  
`before(:each) do
  @user = FactoryBot.create(:user)
end

it "has a valid factory" do
  expect(build(:user)).to be_valid
end

context "validation" do

  it "is valid with valid attributes" do
    expect(@user).to be_a(User)
  end

end

context "associations" do

end

context "public instance methods" do

end`
20. `rails g model Attendance stripe_id:string`
21. `rails db:migrate`
22. dans ./spec/factories/attendances.rb, ajouter :  
`stripe_id { Faker::Internet.password }`
23. dans ./spec/models/attendance_spec.rb, ajouter :  
`before(:each) do
  @attendance = FactoryBot.create(:attendance)
end

it "has a valid factory" do
  expect(build(:attendance)).to be_valid
end

context "validation" do

  it "is valid with valid attributes" do
    expect(@attendance).to be_a(Attendance)
  end

end

context "associations" do

end

context "public instance methods" do

end`
24. `rails g model Event start_date:datetime duration:integer title:string description:text price:integer location:string`
25. `rails db:migrate`
26. dans ./spec/factories/events.rb, ajouter :  
`start_date { Faker::Date.forward(666) }
duration { rand(6..120) * 5 }
title { Faker::Book.title }
description { Faker::Lorem.paragraph(10) }
price { rand(1..1000) }
location { Faker::Address.full_address }`
27. dans ./spec/models/event_spec.rb, ajouter :  
`before(:each) do
  @event = FactoryBot.create(:event)
end

it "has a valid factory" do
  expect(build(:event)).to be_valid
end

context "validation" do

  it "is valid with valid attributes" do
    expect(@event).to be_a(Event)
  end

  describe "#start_date" do
    it { expect(@event).to validate_presence_of(:start_date) }
    it "is not valid if start_date is after end_date" do
      invalid_event = FactoryBot.build(:event, start_date: Time.now - 1)
      expect(invalid_event).not_to be_valid
      expect(invalid_event.errors.include?(:start_date)).to eq(true)
    end
  end

  describe "#duration" do
    it { expect(@event).to validate_presence_of(:duration) }
    it { expect(@event).to validate_numericality_of(:duration).is_greater_than(0) }
    it "should be multiple of 5" do
      invalid_event = FactoryBot.build(:event, duration: 1)
      expect(invalid_event).not_to be_valid
      expect(invalid_event.errors.include?(:duration)).to eq(true)
    end
  end

end`

---
# Création des validations et méthodes pour valider nos tests

28. dans ./app/models/event.rb, ajouter :
`validates_with EventValidator, on: :create

validates :start_date, presence: true
validates :duration,
  presence: true,
  numericality: { greater_than: 0 }`
29. créer un dossier validators dans le dossier app  
`mkdir app/validators` ( depuis la racine de l'application )
30. et à l'intérieur de celui-ci créer un fichier event_validator.rb  
`touch app/validators/event_validator.rb` ( depuis la racine de l'application )
31. dans ce fichier, ajouter :
`class EventValidator < ActiveModel::Validator

  def validate(event)
    cannot_create_event_in_the_past(event)
    duration_should_be_multiple_of_five(event)
  end

  private

  def cannot_create_event_in_the_past(event)
    return unless event.start_date
    event.errors[:start_date] << "cannot create events in the past" if event.start_date < Time.now
  end

  def duration_should_be_multiple_of_five(event)
    return unless event.duration
    event.errors[:duration] << "duration should be multiple of five" unless event.duration % 5 == 0
  end

end`
32. `rspec`  
Tout les tests doivent être OK maintenant.

---
## Création des validations restantes

33. on rajoute encore une fois du contenu au model de Event cette fois ci pour valider le reste de nos attributs :
`validates :title,
  presence: true,
  length: { in: 5..140 }

validates :description,
  presence: true,
  length: { in: 20..1000 }

validates :price,
  presence: true,
  numericality: { greater_than: 0, less_than: 1001}

validates :location, presence: true`

---
## Relations de la DB

### Ajout des admins aux events
34. `rails g migration AddAdminToEvent`
35. ajouter dans la def change de cette migration :  
`def change
  change_table :events do |t|
    t.belongs_to :admin, index: true
  end
end`
36. `rails db:migrate`
37. dans le model Event, ajouter :  
`belongs_to :admin, class_name: 'User'`
38. dans le model User, ajouter :
`has_many :organized_events, foreign_key: 'admin_id', class_name: 'Event'`
39. la relation admin à était ajouter aux events il faut donc rajouter cette relation dans no tests spec. Dans ./spec/factories/events.rb, ajouter :  
`admin { FactoryBot.create(:user) }`
40. vérifier que tout est OK avec un `rspec`

### Ajout des events aux users
41. `rails g migration AddEventsToUsers`
42. dans cette migration ajouter :  
`change_table :attendances do |t|
  t.references :event, index: true
  t.references :user, index: true
end`
43. `rails db:migrate`
44. ajouter dans le model event :  
`has_many :attendances
has_many :users, through: :attendances`
45. ajouter dans le model user :  
`has_many :attendances
has_many :events, through: :attendances`
46. ajouter dans le model attendance :  
`belongs_to :user
belongs_to :event`
47. dans ./spec/factories/attendances.rb, ajouter :  
`user { FactoryBot.create(:user) }
event { FactoryBot.create(:event) }`
48. `rspec` pour vérifier que tout est OK

---
## Seed

49. dans ./db/seeds.rb, ajouter :  
`10.times do
  FactoryBot.create(:user)
end

50.times do
  FactoryBot.create(:event, admin: User.all.sample)
end

200.times do
  FactoryBot.create(:attendance, user: User.all.sample, event: Event.all.sample)
end`  
Félix déconseille néamoins l'utilisation de FactoryBot dans le seeds mais par soucis de temps c'etait plus rapide de faire comme ça.
50. `rails db:seed` pour vérifier que tout est OK

---
## Devise

51. `rails g devise:views`

### Branchement de bootstrap

52. dans ./app/views/layouts/application.html.erb, ajouter entre les balise `<head> </head>` :  
`<!-- Required meta tags -->
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

<!-- Bootstrap CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">`
53. dans le même fichier inclure le `<%= yield %>` dans une div container :  
`<div class="container">
  <%= yield %>
</div>`
54. toujours dans ce fichier, ajouter avant la fermeture de la balise `</body>`:  
`<!-- Optional JavaScript -->
<!-- jQuery first, then Popper.js, then Bootstrap JS -->
<script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
`
55. ajouter juste après l'ouverture de la balise `<body>` :  
`<%= render 'layouts/header' %>`
56. `touch app/views/layouts/_header.html.erb`

### Création des premières views

57. `rails g controller events index new create`
58. dans le fichier ./config/routes.rb remplacer les get générés par rails par :  
`root 'events#index'
resources :events, only: [:new, :create]`
59. lancer le serveur pour vérifier qu'il n'y ai pas d'erreurs `rails s` et aller sur http://localhost:3000/
60. dans le fichier `./app/views/layouts/_header.html.erb` ajouter la navbar :  
`<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <%= link_to 'The BG Events Project', root_path, class: 'navbar-brand' %>
  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNavDropdown" aria-controls="navbarNavDropdown" aria-expanded="false" aria-label="Toggle navigation">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="navbarNavDropdown">
    <ul class="navbar-nav">
      <li class="nav-item active">
        <a class="nav-link" href="#">Créer un événement</a>
      </li>
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
          Mon profil
        </a>
        <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
          <% if user_signed_in? %>
            <%= link_to "Mon profil", '#', class: 'dropdown-item' %>
            <%= link_to "Se déconnecter", destroy_user_session_path, class: 'dropdown-item',method: :delete %>
          <% else %>
            <%= link_to "S'inscrire", new_user_registration_path, class: 'dropdown-item' %>
            <%= link_to "Se connecter", new_user_session_path, class: 'dropdown-item' %>
          <% end %>
        </div>
      </li>
    </ul>
  </div>
</nav>`  
si jamais le menu déroulant de la navbar pose problème cela vient sûrement de turbolinks ( 'rails remove turbolinks' sur google pour la marche à suivre )  
supprimer la ligne 15 du fichier ./app/assets/javascripts/application.js `//= require turbolinks`
61. dans ./app/views/devise/registrations/new.html.erb remplacer le code présent par :  
`<div class="container">
  <div class="row">
    <div class="col-md-6 offset-md-3">
      <br><br><br>
      <%= form_for resource, as: resource_name, url: registration_path(resource_name), html: { class: "form-signin mt-3" } do |f| %>
        <h1 class="h3 mb-3 font-weight-normal text-center">Sign up</h1>
        <%= devise_error_messages! %>
        <div class="form-group">
          <%= f.label :email, "Email" %><br />
          <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "form-control" %>
        </div>
        <div class="form-group">
          <%= f.label :password %>
          <% if @minimum_password_length %>
          <em>(<%= @minimum_password_length %> characters minimum)</em>
          <% end %><br />
          <%= f.password_field :password, autocomplete: "new-password", class: "form-control" %>
        </div>
        <div class="form-group">
          <%= f.label :password_confirmation %><br />
          <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "form-control" %>
        </div>
        <div class="actions mt-5">
          <%= f.submit "Sign up", class: "btn btn-lg btn-primary btn-block" %>
        </div>
      <% end %>
      <%= render "devise/shared/links" %>
    </div>
  </div>
</div>`
62. maintenant dans le fichier ./app/views/events/index.html.erb remplacer le code présent par :  
`<main role="main">

  <section class="jumbotron text-center">
    <div class="container">
      <h1 class="jumbotron-heading">Bienvenue !</h1>
      <p class="lead text-muted">Trouves les événements à Bordeaux</p>
      <p>
        <a href="#" class="btn btn-primary my-2">Inscris-toi</a>
        <a href="#" class="btn btn-secondary my-2">Créé un événement</a>
      </p>
    </div>
  </section>

  <div class="album py-5 bg-light">
    <div class="container">

      <div class="row">
        <% @events.each do |event| %>
          <div class="col-md-4">
            <div class="card mb-4 box-shadow">
              <img class="card-img-top" data-src="holder.js/100px225?theme=thumb&bg=55595c&fg=eceeef&text=Thumbnail" alt="Card image cap">
              <div class="card-body">
                <p class="card-text"><%= event.title %></p>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>

</main>`
63. et dans le controller ./app/controllers/events_controller.rb, ajouter :  
`@events = Event.all`  
dans la def index
