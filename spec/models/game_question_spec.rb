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
      expect(game_question.correct_answer_key).not_to eq('a')
      expect(game_question.correct_answer_key).to eq('b')
      expect(game_question.correct_answer_key).not_to eq('c')
      expect(game_question.correct_answer_key).not_to eq('d')
    end
  end
end
