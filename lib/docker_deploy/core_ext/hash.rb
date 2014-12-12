# Extentions for hash
class Hash
  def symbolize_keys
    _deep_transform_keys_in_object(self) do |key|
      begin
        key.to_sym
      rescue StandardError
        key
      end
    end
  end

  private

  def _deep_transform_keys_in_object(object, &block)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[yield(key)] = _deep_transform_keys_in_object(value, &block)
      end
    when Array
      object.map { |e| _deep_transform_keys_in_object(e, &block) }
    else
      object
    end
  end
end
