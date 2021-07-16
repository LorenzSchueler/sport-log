use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

pub fn impl_verify_for_user(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;
    let unverified_id_typename_str = unverified_id_typename.to_string();
    let typename = Ident::new(
        &unverified_id_typename_str[10..unverified_id_typename_str.len() - 2],
        Span::call_site(),
    );
    let id_typename = Ident::new(&unverified_id_typename_str[10..], Span::call_site());

    let gen = quote! {
        impl #unverified_id_typename {
            pub fn verify(
                self,
                auth: &crate::auth::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<crate::model::#id_typename, rocket::http::Status> {
                let entity = crate::model::#typename::get_by_id(crate::model::#id_typename(self.0), conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.user_id == **auth {
                    Ok(crate::model::#id_typename(self.0))
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_action_provider(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;
    let unverified_id_typename_str = unverified_id_typename.to_string();
    let typename = Ident::new(
        &unverified_id_typename_str[10..unverified_id_typename_str.len() - 2],
        Span::call_site(),
    );
    let id_typename = Ident::new(&unverified_id_typename_str[10..], Span::call_site());

    let gen = quote! {
        impl #unverified_id_typename {
            pub fn verify(
                self,
                auth: &crate::auth::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<crate::model::#id_typename, rocket::http::Status> {
                let entity = crate::model::#typename::get_by_id(crate::model::#id_typename(self.0), conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.action_provider_id == **auth {
                    Ok(crate::model::#id_typename(self.0))
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}
pub fn impl_verify_for_admin(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;
    let unverified_id_typename_str = unverified_id_typename.to_string();
    let id_typename = Ident::new(&unverified_id_typename_str[10..], Span::call_site());

    let gen = quote! {
        impl #unverified_id_typename {
            pub fn verify_adm(
                self,
                auth: &crate::auth::AuthenticatedAdmin,
            ) -> Result<crate::model::#id_typename, rocket::http::Status> {
                    Ok(crate::model::#id_typename(self.0))
            }
        }
    };
    gen.into()
}
pub fn impl_inner_int_from_param(ast: &syn::DeriveInput) -> TokenStream {
    let unverified_id_typename = &ast.ident;

    let gen = quote! {
        impl<'v> rocket::request::FromParam<'v> for #unverified_id_typename{
            type Error = &'v str;

            fn from_param(param: &'v str) -> Result<Self, Self::Error> {
                Ok(Self(i32::from_param(param)?))
            }
        }
    };
    gen.into()
}
