# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  let(:game_timeout) do
    FactoryGirl.create(:game_with_questions, user: user, created_at: Time.now - 35.minutes)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect do
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      end.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq :in_progress
      expect(game_w_questions.finished?).to eq false
    end

    it 'situation when take money' do
      # берем текущую игру и отвечаем на вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
    
      # взяли деньги
      game_w_questions.take_money!
    
      prize = game_w_questions.prize
      expect(prize).to be > 0
    
      # проверяем что закончилась игра и пришли деньги игроку
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to eq true
      expect(user.balance).to eq prize
    end

    # группа тестов на проверку статуса игры
    context '.status' do
      # перед каждым тестом "завершаем игру"
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.finished?).to eq true
      end

      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq :won
      end

      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq :fail
      end

      it ':timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq :timeout
      end

      it ':money' do
        expect(game_w_questions.status).to eq :money
      end
    end

    describe '#previous_level' do
      it 'return previous level game' do
        # на начало игры уровень 0 предыдущий уровень равень -1
        expect(game_w_questions.previous_level).to eq(-1)
        # задаем уровень 5
        game_w_questions.current_level = 5
        expect(game_w_questions.previous_level).to eq(4)
        # задаем уровень 10
        game_w_questions.current_level = 10
        expect(game_w_questions.previous_level).to eq(9)

        expect(game_w_questions.finished?).to eq false
      end

      it 'should finish game with status in_progress' do
        expect(game_w_questions.status).to eq :in_progress
      end
    end

    describe '#current_game_question' do
      it 'return correct level question' do
        game_w_questions.current_level = 5
        question = game_w_questions.current_game_question
        expect(game_w_questions.current_game_question).to eq(question)

        # при изменении уровня игры вопрос меняется
        game_w_questions.current_level = 12
        expect(game_w_questions.current_game_question).not_to eq(question)

        expect(game_w_questions.finished?).to eq false
      end

      it 'should finish game with status in_progress' do
        expect(game_w_questions.status).to eq :in_progress
      end
    end

    describe '#answer_current_question!' do
      context 'when answer is wrong' do
        let(:answer_correct) { game_w_questions.current_game_question.correct_answer_key }
        let(:wrong_answer_key) do
          %w[a b c d].reject { |n| n == answer_correct }.sample
        end

        before { game_w_questions.answer_current_question!(wrong_answer_key) }

        it 'should finish game with status fail' do
          expect(game_w_questions.status).to eq :fail
        end

        it 'checking that the game is over' do
          expect(game_w_questions.finished?).to eq true
        end
      end

      context 'when answer is correct' do
        let(:correct_answer_key) { game_w_questions.current_game_question.correct_answer_key }

        before { game_w_questions.answer_current_question!(correct_answer_key) }

        it 'should return game with status in_progress' do
          expect(game_w_questions.status).to eq :in_progress
        end

        it 'checking that the game is still running' do
          expect(game_w_questions.finished?).to eq false
        end
      end

      context 'and question is last' do
        before do
          game_w_questions.current_level = 14
          correct_answer_key = game_w_questions.current_game_question.correct_answer_key
          game_w_questions.answer_current_question!(correct_answer_key)
        end

        it 'should assign final prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.last)
        end

        it 'should finish game with status won' do
          expect(game_w_questions.status).to eq :won
        end

        it 'checking that the game is over' do
          expect(game_w_questions.finished?).to eq true
        end
      end

      context 'and question is not last' do
        before do
          game_w_questions.current_level = 4
          correct_answer_key = game_w_questions.current_game_question.correct_answer_key
          game_w_questions.answer_current_question!(correct_answer_key)
        end

        it 'should increase the current level by 1' do
          expect(game_w_questions.current_level).to eq(5)
        end

        it 'should continue game' do
          expect(game_w_questions.status).to eq :in_progress
        end

        it 'checking that the game is still running' do
          expect(game_w_questions.finished?).to eq false
        end
      end

      context 'and time is out ' do
        before do
          correct_answer_key = game_timeout.current_game_question.correct_answer_key
          game_timeout.answer_current_question!(correct_answer_key)
        end

        it 'should finish game with status timeout' do
          expect(game_timeout.status).to eq :timeout
        end

        it 'checking that the game is still running' do
          expect(game_w_questions.finished?).to eq false
        end
      end
    end
  end
end
