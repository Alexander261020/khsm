# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  # Группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    # тест на наличие методов делегатов level и text
    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  # Проверяем метод correct_answer_key
  context 'testing method correct_answer_key' do
    it 'getting the key of the correct answer' do
      # Метод correct_answer_key возвращает ключ правильного ответа 'a', 'b', 'c', 'd'
      # Поскольку под буквой 'b' в тесте спрятан правильный ответ то и получить должны 'b'
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      # Проверяем, что объект не включает эту подсказку
      expect(game_question.help_hash).not_to include(:audience_help)
  
      # Добавили подсказку. Этот метод реализуем в модели
      # GameQuestion
      game_question.add_audience_help
  
      # Ожидаем, что в хеше появилась подсказка
      expect(game_question.help_hash).to include(:audience_help)
  
      # Дёргаем хеш
      ah = game_question.help_hash[:audience_help]
      # Проверяем, что входят только ключи a, b, c, d
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  # проверяем работу 50/50
  it 'correct #fifty_fifty' do
    # сначала убедимся, в подсказках пока нет нужного ключа
    expect(game_question.help_hash).not_to include(:fifty_fifty)
    # вызовем подсказку
    game_question.add_fifty_fifty

    # проверим создание подсказки
    expect(game_question.help_hash).to include(:fifty_fifty)
    ff = game_question.help_hash[:fifty_fifty]

    expect(ff).to include('b') # должен остаться правильный вариант
    expect(ff.size).to eq 2 # всего должно остаться 2 варианта
  end

  # проверяем работу подсказки звонок другу
  describe '#add_friend_call' do
    # сначала убедимся, в подсказках пока нет нужного ключа
    it 'Checking the absence of the required key' do
      expect(game_question.help_hash).not_to include(:friend_call)
    end

    # вызовем подсказку
    it 'Checking the availability of the required key' do
      game_question.add_friend_call
      expect(game_question.help_hash).to include(:friend_call)
    end

    it 'Check if the string matches a regular expression' do
      game_question.add_friend_call
      friend_call = game_question.help_hash[:friend_call]
      # проверим что возвращаемое значение является заданной строкой с вариантом ответа
      expect(friend_call).to match(/[а-я\s]+[считает, что это вариант]+[abcd]+/i)
    end
  end
end
