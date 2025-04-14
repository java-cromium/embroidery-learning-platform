require './app'

task :create_admin do
  # Default admin credentials
  email = 'admin@example.com'
  username = 'admin'
  password = 'admin123'

  ActiveRecord::Base.transaction do
    # Create user with admin flag
    user = User.create!(
      email: email,
      username: username,
      password: password,
      password_confirmation: password,
      admin: true
    )

    # Create admin role if it doesn't exist
    admin_role = AdminRole.find_or_create_by!(
      name: 'Super Admin',
      permissions: {
        users: ['read', 'write', 'delete'],
        courses: ['read', 'write', 'delete'],
        lessons: ['read', 'write', 'delete'],
        subscriptions: ['read', 'write', 'delete'],
        admin: ['read', 'write', 'delete']
      }
    )
    
    # Assign admin role to user
    AdminRoleAssignment.create!(
      user: user,
      admin_role: admin_role
    )
    
    puts "\nAdmin user created successfully!"
    puts "Email: #{email}"
    puts "Username: #{username}"
    puts "Password: #{password}"
  end
rescue => e
  puts "\nError creating admin user:"
  puts e.message
end
