require 'optparse'

# Helper methods
def format_number(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def format_money(amount)
  "$#{format_number(amount)}"
end

def play_again?
  print "\nWould you like to play again? (Y/n): "
  answer = gets.chomp.downcase
  answer.empty? || answer.start_with?('y')
end

def get_number_of_games
  print "How many games would you like to play? (default #{format_number(10)}): "
  games = gets.chomp
  return 10 if games.empty?
  games.to_i.abs
end

def get_initial_balance
  print "Enter starting balance (default #{format_money(1)}): $"
  balance = gets.chomp
  return 1 if balance.empty?
  balance.to_i.abs
end

def get_min_wager(initial_balance)
  print "Enter minimum wager amount (default #{format_money(1)}, 'm' for max): $"
  wager = gets.chomp.downcase
  return 1 if wager.empty?
  return initial_balance if wager == 'm'
  [wager.to_i.abs, initial_balance].min
end

def get_flip_count
  print "How many times would you like to flip the coin? (1-#{format_number(1000000)}, default #{format_number(10000)}): "
  count = gets.chomp.downcase
  return 10000 if count.empty?
  return 1000000 if count == 'm'
  [[1, count.to_i].max, 1000000].min
end

def flip_coin
  result = rand(2) == 0 ? "Heads" : "Tails"
  puts "Flipping the coin..."
  sleep(SLEEP_DELAY) if SLEEP_DELAY > 0
  puts "The coin landed on: #{result}!"
  result
end

def play_session(num_games, initial_balance, min_wager, flip_count)
  session_stats = {
    games_played: 0,
    total_flips: 0,
    total_heads: 0,
    total_tails: 0,
    highest_balance: 0,
    games_won: 0,
    total_final_balance: 0,
    total_profit: 0
  }

  num_games.times do |game_num|
    puts "\nGame #{game_num + 1} of #{format_number(num_games)}"
    puts "------------------------"
    
    balance = initial_balance
    max_balance = balance
    wager = min_wager
    puts "Starting balance: #{format_money(balance)}"
    puts "Minimum wager: #{format_money(min_wager)}"

    results = { "Heads" => 0, "Tails" => 0 }
    
    flip_count.times do |i|
      result = flip_coin
      results[result] += 1
      
      if result == "Heads"
        balance += wager
        max_balance = [max_balance, balance].max
        puts "You won #{format_money(wager)}! Balance: #{format_money(balance)}"
        wager = min_wager
      else
        if balance < wager
          wager = balance
          balance = 0
          puts "You lost #{format_money(wager)}! Balance: #{format_money(balance)}"
          puts "Insufficient funds! Game over."
          break
        end
        balance -= wager
        puts "You lost #{format_money(wager)}! Balance: #{format_money(balance)}"
        if balance == 0
          puts "Balance is zero! Game over."
          break
        end
        wager *= 2
        wager = [wager, balance].min
      end
    end

    total_flips = results['Heads'] + results['Tails']
    session_stats[:total_flips] += total_flips
    session_stats[:total_heads] += results['Heads']
    session_stats[:total_tails] += results['Tails']
    session_stats[:highest_balance] = [session_stats[:highest_balance], max_balance].max
    session_stats[:games_played] += 1
    session_stats[:games_won] += 1 if balance > initial_balance

    session_stats[:total_final_balance] += balance
    session_stats[:total_profit] += (balance - initial_balance)

    puts "\nGame #{game_num + 1} Results:"
    puts "Total flips: #{format_number(total_flips)}"
    puts "Heads: #{format_number(results['Heads'])} (#{(results['Heads'].to_f/total_flips*100).round(1)}%)"
    puts "Tails: #{format_number(results['Tails'])} (#{(results['Tails'].to_f/total_flips*100).round(1)}%)"
    puts "Starting balance: #{format_money(initial_balance)}"
    puts "Final balance: #{format_money(balance)}"
    puts "Maximum balance: #{format_money(max_balance)}"
    if balance > initial_balance
      puts "You WON this game! (Profit: #{format_money(balance - initial_balance)})"
    else
      puts "You LOST this game! (Loss: #{format_money(initial_balance - balance)})"
    end
  end

  puts "\n=== Session Summary ==="
  puts "Games played: #{format_number(session_stats[:games_played])}"
  puts "Total flips: #{format_number(session_stats[:total_flips])}"
  total_flips = session_stats[:total_flips].to_f
  puts "Total Heads: #{format_number(session_stats[:total_heads])} (#{(session_stats[:total_heads]/total_flips*100).round(1)}%)"
  puts "Total Tails: #{format_number(session_stats[:total_tails])} (#{(session_stats[:total_tails]/total_flips*100).round(1)}%)"
  puts "Highest balance reached: #{format_money(session_stats[:highest_balance])}"
  puts "Games won: #{format_number(session_stats[:games_won])} (#{(session_stats[:games_won].to_f/session_stats[:games_played]*100).round(1)}%)"
  
  puts "\nBalance Summary:"
  puts "Starting balance per game: #{format_money(initial_balance)}"
  puts "Total final balance: #{format_money(session_stats[:total_final_balance])}"
  puts "Total profit/loss: #{format_money(session_stats[:total_profit])}"
end

# Parse command line options
options = { sleep: 0 }  # Default to no delay
OptionParser.new do |opts|
  opts.banner = "Usage: ruby coinflip.rb [options]"

  opts.on("-s", "--slow", "Run with delay (0.05s)") do
    options[:sleep] = 0.05
  end

  opts.on("-d", "--delay DELAY", Float, "Set custom delay in seconds") do |delay|
    options[:sleep] = delay
  end
end.parse!

SLEEP_DELAY = options[:sleep]

# Main program loop
loop do
  puts "\n=== New Gaming Session ==="
  
  # Get inputs
  num_games = get_number_of_games
  initial_balance = get_initial_balance
  min_wager = get_min_wager(initial_balance)
  flip_count = get_flip_count
  
  # Play session
  play_session(num_games, initial_balance, min_wager, flip_count)
  
  break unless play_again?
end

puts "\nThanks for playing!"
