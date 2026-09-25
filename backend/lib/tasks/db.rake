namespace :db do
  desc "Seed demo data only when no employees exist yet (safe to run on every boot)"
  task seed_if_empty: :environment do
    if Employee.exists?
      puts "Employees present; skipping seed."
    else
      Rake::Task["db:seed"].invoke
    end
  end
end
