# frozen_string_literal: true

require "io/console"

module AdminAccountTasks
  module_function

  def confirmed_password
    password = IO.console.getpass("Password: ")
    confirmation = IO.console.getpass("Confirm password: ")
    return password if password == confirmation

    raise ArgumentError, "Passwords do not match"
  end
end

namespace :admin do
  desc "Provision an administrator with EMAIL and OPERATOR"
  task provision: :environment do
    password = AdminAccountTasks.confirmed_password
    account = AdminAccountManager.new.provision!(
      email: ENV.fetch("EMAIL"),
      password:,
      password_confirmation: password,
      operator_identifier: ENV.fetch("OPERATOR")
    )
    puts "Administrator provisioned: #{account.email}"
  end

  desc "Reset an administrator password with EMAIL and OPERATOR"
  task reset_password: :environment do
    password = AdminAccountTasks.confirmed_password
    account = AdminAccountManager.new.reset_password!(
      email: ENV.fetch("EMAIL"),
      password:,
      password_confirmation: password,
      operator_identifier: ENV.fetch("OPERATOR")
    )
    puts "Administrator password reset: #{account.email}"
  end
end
