module MaskingUtil
  extend self

  def mask_data(data, pii_masking)
    return data if pii_masking.blank?

    # Base case: If data is not a hash or array, return it as is
    return data unless data.is_a?(Hash) || data.is_a?(Array)

    # If the data is an array, apply the function recursively to each element
    if data.is_a?(Array)
      return data.map { |value| MaskingUtil.mask_data(value, pii_masking) }
    end

    # If the data is a hash, transform each value
    data.transform_keys! { |k| k.to_s.downcase } # Convert keys to downcase for case-insensitive comparison
    data.each do |key, value|
      if pii_masking.include?(key.downcase)  # Check if the key matches PII fields (case-insensitive)
        data[key] = 'MASKED_' + '{{' + key + '}}'               # Mask the value
      elsif value.is_a?(Hash) || value.is_a?(Array)
        data[key] = MaskingUtil.mask_data(value, pii_masking)  # Recurse for nested hashes or arrays
      end
    end
  end

  def mask_query_params(url, pii_masking)
    return url if pii_masking.blank?
    uri = URI.parse(url)
    query_params = CGI.parse(uri.query || '')  # Parse query params into a hash

    # Mask sensitive query params
    query_params.each do |key, values|
      if pii_masking.include?(key.downcase)  # Check if key matches PII fields (case-insensitive)
        query_params[key] = ['{{' + 'MASKED_' + key + '}}']        # Replace value with 'XXXX'
      end
    end

    # Reconstruct the query string with masked values
    uri.query = URI.encode_www_form(query_params)

    uri.to_s  # Return the new URL with masked query params
  end

end