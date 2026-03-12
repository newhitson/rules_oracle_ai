require 'rails_helper'

RSpec.describe Question, type: :model do
  subject(:question) { Question.new(text: "Can a creature with flying be blocked?", confidence: "sufficient") }

  it "is valid with text and confidence" do
    expect(question).to be_valid
  end

  it "is invalid without text" do
    question.text = nil
    expect(question).not_to be_valid
  end

  it "is invalid with blank text" do
    question.text = ""
    expect(question).not_to be_valid
  end

  it "is invalid with an unrecognised confidence value" do
    question.confidence = "maybe"
    expect(question).not_to be_valid
  end

  it "is valid with confidence: insufficient" do
    question.confidence = "insufficient"
    expect(question).to be_valid
  end

  it "is valid with confidence: pending" do
    question.confidence = "pending"
    expect(question).to be_valid
  end
end
