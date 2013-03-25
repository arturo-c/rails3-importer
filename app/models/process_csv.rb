class ProcessCsv
  @queue = :process_csv

  def self.perform(chunk)
    Member.collection.insert(chunk)
  end

end