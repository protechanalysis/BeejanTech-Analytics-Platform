from cryptography.fernet import Fernet
import secrets
import subprocess
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')

try:
    fernet_key = Fernet.generate_key().decode()
    secret_key = secrets.token_hex(32)
    logging.info("Keys generated successfully.")
except Exception as e:
    logging.error(f"Error generating keys: {e}", exc_info=True)
    raise

def put_ssm_param(name, value):
    try:
        subprocess.run([
            "aws", "ssm", "put-parameter",
            "--name", name,
            "--value", value,
            "--type", "SecureString",
            "--overwrite"
        ], check=True)
        logging.info(f"Stored {name} in SSM successfully.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error storing {name} in SSM: {e}", exc_info=True)
        raise
    except Exception as e:
        logging.error(f"Unexpected error storing {name} in SSM: {e}", exc_info=True)
        raise

try:
    put_ssm_param("fernet_key", fernet_key)
    put_ssm_param("secret_key", secret_key)
except Exception as e:
    logging.error("Failed to store one or more secrets in SSM.")
