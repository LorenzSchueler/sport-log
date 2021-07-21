use std::env;

use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use rand_core::OsRng;

fn main() {
    let args: Vec<_> = env::args().collect();

    match &args[1..] {
        [mode, password] if mode == "-g" => {
            let salt = SaltString::generate(&mut OsRng);
            let password_hash = Argon2::default()
                .hash_password_simple(password.as_bytes(), salt.as_ref())
                .unwrap()
                .to_string();

            println!("{}", password_hash);
        }
        [mode, hash, password] if mode == "-v" => {
            let hash = PasswordHash::new(hash.as_str()).unwrap();
            if Argon2::default()
                .verify_password(password.as_bytes(), &hash)
                .is_ok()
            {
                println!("password matches hash");
            } else {
                println!("password does not match hash");
            }
        }
        _ => {
            println!(
                "sport-log-password-hasher\n\n\
                
                OPTIONS:\n\
                -g <password>\t\tgenerate hash\n\
                -v <hash> <password>\tverify password"
            );
        }
    }
}
