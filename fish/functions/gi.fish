function gi -d 'Get gitignore file from toptal.com'
  curl -sL https://www.toptal.com/developers/gitignore/api/$argv
end
