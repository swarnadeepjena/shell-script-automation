#merge github branch automatically by cronjob

#run below script as cron job then the develop & qa branch will autometically merge
#create a directory as src-certiplate-v3-backend & pull the code & execute the script
#also you can send notification via slacks

------------------------------------------------------------------------------
#!/bin/bash


# Exit the script if any command fails
set -e

# Ensure you are in the correct directory
cd /home/auto-merge/certiplate-v3-backend/src-certiplate-v3-backend


# Slack webhook URL (replace with your actual webhook URL)
slack_webhook_url="***"


# Define the commit message
commit_message="Auto-merge:Certiplate-Backend (Develop to QA) $(date +'%Y-%m-%d %H:%M:%S')"

git checkout develop
git pull origin develop


# Checkout the 'qa' branch
git checkout qa

# Pull the latest changes from the remote 'qa' branch
git pull origin qa

# Merge 'develop' into 'qa' using the 'theirs' strategy

#if git merge -X theirs -m "$commit_message" origin/develop; then
if git merge -m "$commit_message" origin/develop; then
  echo "Merging was successful!"
  # Push the updated 'qa' branch to the remote repository
  git push origin qa

  # Send a Slack notification for success
  slack_message="Certiplate-Backend-v3:Auto-Merging of 'develop' into 'qa' was successful! $(date +'%Y-%m-%d %H:%M:%S')"
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$slack_message\"}" "$slack_webhook_url"
else
  echo "Merging failed. Please check for conflicts and resolve them."


  # Send a Slack notification for failure
  slack_message="Certiplate-Backend-v3:Merging of 'develop' into 'qa' failed. Please check for conflicts and resolve them. $(date +'%Y-%m-%d %H:%M:%S')"
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$slack_message\"}" "$slack_webhook_url"

  exit 1  # Exit the script with an error status
fi
