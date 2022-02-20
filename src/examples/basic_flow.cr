wait_on_request :slash_command

work_request_form = basic_form do
  select_input  :work_type do
    option :it_request
    option :incident
    option :saying_hello, text: "Saying hello!"
  end

  textarea_input :description
end

personal_info_form = basic_form do
  string_input  :first_name
  string_input  :last_name
  email_input   :email, optional: true

  select_input  :career do
    option :some_job1
    option :some_job2
    option :some_job3
  end
end

send :work_request, to: cory, form: work_request_form
in_parallel do
  send :personal_info, to: cory, form: personal_info_form

  get_approval :work_approval, from: stakeholders do
    only_require        2.approvals
    fail_after          1.denial
    escalate_strategy   :one_at_a_time
    escalate_after      5.minutes
  end
end

in_background do
  send :stakeholder_info, to: stakeholders, form: personal_info_form
end
