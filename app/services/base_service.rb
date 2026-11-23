class BaseService
  Result = Data.define(:value, :error) do
    def success?
      error.nil?
    end
  end

  private

  def success(value)
    Result.new(value: value, error: nil)
  end

  def failure(error)
    Result.new(value: nil, error: error)
  end
end
