# Local shell secrets template.
# Copy the variable names you actually use and replace the placeholder values locally.

# OpenAI
export OPENAI_API_KEY='your_openai_api_key_here'

# NVIDIA / NGC
export NGC_API_KEY='your_ngc_api_key_here'
export NVIDIA_API_KEY='your_nvidia_api_key_here'

# Hugging Face
export HF_TOKEN='your_hugging_face_token_here'
export HUGGING_FACE_HUB_TOKEN='your_hugging_face_hub_token_here'

# Weights & Biases
export WANDB_API_KEY='your_wandb_api_key_here'
export WANDB_BASE_URL='https://your-wandb-instance.example.com'
export WANDB_ENTITY='your_wandb_entity_here'
export WANDB_PROJECT='your_wandb_project_here'

# Private aliases and other local-only shell settings.
alias homelab='ssh homelab@<your-homelab-ip>'
