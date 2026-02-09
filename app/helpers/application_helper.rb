module ApplicationHelper
  def remaining_ymd_text(days)
    return "0日" if days <= 0

    today = Date.current
    target = today + days

    years  = target.year  - today.year
    months = target.month - today.month
    days   = target.day   - today.day

    if days < 0
      months -= 1
      days += (today >> (years * 12 + months)).end_of_month.day
    end

    if months < 0
      years -= 1
      months += 12
    end

    parts = []
    parts << "#{years}年"   if years.positive?
    parts << "#{months}ヶ月" if months.positive?
    parts << "#{days}日"    if days.positive?

    parts.join(" ")
  end
end
