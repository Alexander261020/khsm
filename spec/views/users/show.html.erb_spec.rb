require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    # Перед каждым шагом мы пропишем в переменную @user пользователя, 
    # имитируя действие контроллера, который эти данные будет брать из базы
    # Обратите внимание, что мы объекты в базу не кладем, т.к. пишем FactoryGirl.build_stubbed
    current_user = assign(:user, FactoryGirl.build_stubbed(:user, name: 'NameUser', balance: 5000))
    # Разрешаем объекту view в ответ на вызов current_user возвращать current_user
    allow(view).to receive(:current_user).and_return(current_user)
    # создаем игру
    assign(:games, [FactoryGirl.build_stubbed(:game)])
    stub_template 'users/_game.html.erb' => 'User game goes here'

    render
  end

  # Этот сценарий проверяет, что шаблон выводит имя игрока
  it 'renders player name' do
    expect(rendered).to match 'NameUser'
  end

  # Этот сценарий проверяет, что шаблон выводит смену имени и пароля
  it 'checking the rendering of the password change button' do
    expect(rendered).to match 'Сменить имя и пароль'
  end

  # Проверяем отрисовку фрагмента с игрой
  it 'check a fragment with the game is drawn' do
    expect(rendered).to match 'User game goes here'
  end
end
