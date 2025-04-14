# Embroidery Learning Platform

A modern web application for learning embroidery, featuring video lessons, social media integration, and a rich history of embroidery.

## Features

- User authentication (email/password and social media)
- Free and premium content tiers
- Video lessons
- Social media integration (Instagram, TikTok, X/Twitter, Facebook)
- Live social media gallery
- Embroidery history content
- About us page

## Tech Stack

- Ruby (Sinatra)
- PostgreSQL
- Redis
- Sidekiq
- AWS S3 (video storage)
- Social Media APIs
- Tailwind CSS

## Setup

1. Clone the repository
2. Install dependencies:
```bash
bundle install
```

3. Copy the environment file and configure your variables:
```bash
cp .env.example .env
```

4. Set up the database:
```bash
rake db:create
rake db:migrate
```

5. Start the Redis server:
```bash
redis-server
```

6. Start Sidekiq:
```bash
bundle exec sidekiq
```

7. Start the application:
```bash
bundle exec rackup
```

The application will be available at http://localhost:9292

## Development

- `bundle exec shotgun` - Start the development server with auto-reload
- `bundle exec rake -T` - View available rake tasks
- `bundle exec rspec` - Run the test suite

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.
