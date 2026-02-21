require 'rake'

RSpec.shared_context 'rake task' do
  before(:all) do
    Rails.application.load_tasks
  end

  subject(:task) { Rake::Task[task_name] }

  before { task.reenable }
end
