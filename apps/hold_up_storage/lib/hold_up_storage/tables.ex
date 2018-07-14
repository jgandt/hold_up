defmodule HoldUpStorage.Mnesia do
  def setup do
    :mnesia.create_schema([node()])
    :mnesia.start()
  end

  def build_tables do
    :mnesia.create_table(Tasks, [attributes: [:name, :ttl], disc_copies: [node()]])

    :mnesia.create_table(Completions, [attributes: [:name, :expires_at], disc_copies: [node()]])
  end
end
