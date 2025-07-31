def ask_question(question)
  # question = {"question"=>"What do you want?", "type"=>"text/boolean/number/list", "options"=>["option1","option2"], "var"=>"VAR_NAME"}
  case question['type']
  when "boolean"
    answer = @prompt.yes?(question['question'])
  when "list"
    answer = @prompt.select(question['question'], question['options'])
  when "text"
    answer = @prompt.ask(question['question'])
  when "number"
    answer = @prompt.ask(question['question']) do |q|
      q.validate(/^[0-9]*$/, "Answer must be a number or empty")
    end
  end
  return answer
end
