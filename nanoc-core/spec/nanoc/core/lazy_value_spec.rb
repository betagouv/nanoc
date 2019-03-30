# frozen_string_literal: true

describe Nanoc::Core::LazyValue do
  describe '#value' do
    subject { lazy_value.value }

    let(:value_arg) { +'Hello world' }
    let(:lazy_value) { described_class.new(value_arg) }

    context 'object' do
      it { is_expected.to equal(value_arg) }
    end

    context 'proc' do
      it 'does not call the proc immediately' do
        expect(value_arg).not_to receive(:call)

        lazy_value
      end

      it 'returns proc return value' do
        expect(value_arg).to receive(:call).once.and_return('Hello proc')

        expect(subject).to eql('Hello proc')
      end

      it 'only calls the proc once' do
        expect(value_arg).to receive(:call).once.and_return('Hello proc')

        expect(subject).to eql('Hello proc')
        expect(subject).to eql('Hello proc')
      end
    end
  end

  describe '#map' do
    subject { lazy_value.map(&:upcase) }

    let(:value_arg) { -> { 'Hello world' } }
    let(:lazy_value) { described_class.new(value_arg) }

    it 'does not call the proc immediately' do
      expect(value_arg).not_to receive(:call)

      subject
    end

    it 'returns proc return value' do
      expect(value_arg).to receive(:call).once.and_return('Hello proc')

      expect(subject.value).to eql('HELLO PROC')
    end

    it 'only calls the proc once' do
      expect(value_arg).to receive(:call).once.and_return('Hello proc')

      expect(subject.value).to eql('HELLO PROC')
      expect(subject.value).to eql('HELLO PROC')
    end
  end

  describe '#freeze' do
    subject { described_class.new(value_arg) }

    let(:value_arg) { 'Hello world' }

    context 'freeze before calling #value' do
      before do
        subject.freeze
      end

      context 'object' do
        it 'returns value' do
          expect(subject.value).to equal(value_arg)
        end

        it 'freezes value' do
          expect(subject.value).to be_frozen
        end
      end

      context 'proc' do
        call_count = 0
        let(:value_arg) do
          proc do
            call_count += 1
            'Hello proc'
          end
        end

        before do
          call_count = 0
          subject.freeze
        end

        it 'does not call the proc immediately' do
          expect(call_count).to be(0)
        end

        it 'returns proc return value' do
          expect(subject.value).to eq('Hello proc')
        end

        it 'freezes upon access' do
          expect(subject.value).to be_frozen
        end
      end
    end

    context 'freeze after calling #value' do
      before do
        subject.value
        subject.freeze
      end

      context 'object' do
        it 'returns value' do
          expect(subject.value).to equal(value_arg)
        end

        it 'freezes value' do
          expect(subject.value).to be_frozen
        end
      end

      context 'proc' do
        call_count = 0
        let(:value_arg) do
          proc do
            call_count += 1
            'Hello proc'
          end
        end

        before do
          call_count = 0
          subject.freeze
        end

        it 'does not call the proc immediately' do
          expect(call_count).to be(0)
        end

        it 'returns proc return value' do
          expect(subject.value).to eq('Hello proc')
        end

        it 'freezes upon access' do
          expect(subject.value).to be_frozen
        end
      end
    end
  end
end
