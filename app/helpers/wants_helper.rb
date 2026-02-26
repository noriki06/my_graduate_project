module WantsHelper
  def bucket_subname(bucket)
    return "" if bucket.blank?

    start_age = bucket.to_s.split("-").first.to_i

    case start_age
    when 20 then "青年期"
    when 30, 40 then "壮年期"
    when 50 then "中年期"
    when 60 then "高齢期前期"
    when 70, 80 then "高齢期"
    else ""
    end
  end
end
