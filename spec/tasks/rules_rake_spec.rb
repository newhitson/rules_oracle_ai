require 'rails_helper'

RSpec.describe 'rules:seed' do
  include_context 'rake task'

  let(:task_name) { 'rules:seed' }
  let(:file_path) { Rails.root.join('comprehensive_rules_modified.txt') }

  before do
    CompRulesEmbedding.delete_all
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(file_path).and_return(true)
    allow(File).to receive(:foreach).and_call_original
  end

  def stub_lines(*lines)
    allow(File).to receive(:foreach).with(file_path) do |&block|
      lines.each { |line| block.call("#{line}\n") }
    end
  end

  describe 'parsing rules' do
    it 'imports a numeric rule with top_level_section and title' do
      stub_lines(
        '1. Game Concepts',
        '100. General',
        '100.1. These Magic rules apply to any Magic game.'
      )

      task.invoke

      rule = CompRulesEmbedding.find_by(section_number: '100.1')
      expect(rule).to be_present
      expect(rule.top_level_section).to eq('Game Concepts')
      expect(rule.title).to eq('General')
      expect(rule.content).to eq('These Magic rules apply to any Magic game.')
    end

    it 'imports a lettered rule' do
      stub_lines(
        '1. Game Concepts',
        '100. General',
        '100.1a A two-player game is a game that begins with only two players.'
      )

      task.invoke

      rule = CompRulesEmbedding.find_by(section_number: '100.1a')
      expect(rule).to be_present
      expect(rule.top_level_section).to eq('Game Concepts')
      expect(rule.title).to eq('General')
      expect(rule.content).to eq('A two-player game is a game that begins with only two players.')
    end

    it 'imports a multi-digit numeric rule' do
      stub_lines(
        '1. Game Concepts',
        '106. Mana',
        '106.10. Some multi-digit rule text.'
      )

      task.invoke

      rule = CompRulesEmbedding.find_by(section_number: '106.10')
      expect(rule).to be_present
      expect(rule.content).to eq('Some multi-digit rule text.')
    end

    it 'imports a multi-digit lettered rule' do
      stub_lines(
        '1. Game Concepts',
        '106. Mana',
        '106.10a Some multi-digit lettered rule text.'
      )

      task.invoke

      rule = CompRulesEmbedding.find_by(section_number: '106.10a')
      expect(rule).to be_present
      expect(rule.content).to eq('Some multi-digit lettered rule text.')
    end

    it 'does not store top-level section headers as records' do
      stub_lines('1. Game Concepts')

      task.invoke

      expect(CompRulesEmbedding.count).to eq(0)
    end

    it 'does not store 3-digit section headers as records' do
      stub_lines('100. General')

      task.invoke

      expect(CompRulesEmbedding.count).to eq(0)
    end
  end

  describe 'upsert behavior' do
    it 'updates an existing record on re-run without creating duplicates' do
      stub_lines(
        '1. Game Concepts',
        '100. General',
        '100.1. Original content.'
      )
      task.invoke
      task.reenable

      stub_lines(
        '1. Game Concepts',
        '100. General',
        '100.1. Updated content.'
      )
      task.invoke

      expect(CompRulesEmbedding.count).to eq(1)
      expect(CompRulesEmbedding.find_by(section_number: '100.1').content).to eq('Updated content.')
    end
  end

  describe 'missing file' do
    it 'prints an error and exits when the file does not exist' do
      allow(File).to receive(:exist?).with(file_path).and_return(false)

      expect { task.invoke }.to output(/File not found/).to_stdout.and raise_error(SystemExit)
    end
  end
end
