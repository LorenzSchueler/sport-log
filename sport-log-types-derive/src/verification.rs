use proc_macro::TokenStream;
use proc_macro2::{Ident, Span};
use quote::quote;

pub fn impl_verify_id_for_user(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;
    let id_typename_str = id_typename.to_string();
    let typename = Ident::new(
        &id_typename_str[..id_typename_str.len() - 2],
        Span::call_site(),
    );

    let gen = quote! {
        impl crate::types::VerifyIdForUser for crate::types::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify(
                self,
                auth: &crate::types::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Self::Id, rocket::http::Status> {
                use crate::types::GetById;

                let entity = crate::types::#typename::get_by_id(self.0, conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.user_id == **auth {
                    Ok(self.0)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_id_for_user_unchecked(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;

    let gen = quote! {
        impl crate::types::VerifyIdForUserUnchecked for crate::types::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_unchecked(
                self,
                auth: &crate::types::AuthenticatedUser,
            ) -> Result<crate::types::#id_typename, rocket::http::Status> {
                Ok(self.0)
            }
        }
    };
    gen.into()
}

pub fn impl_verify_id_for_action_provider(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;
    let id_typename_str = id_typename.to_string();
    let typename = Ident::new(
        &id_typename_str[..id_typename_str.len() - 2],
        Span::call_site(),
    );

    let gen = quote! {
        impl crate::types::VerifyIdForActionProvider for crate::types::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_ap(
                self,
                auth: &crate::types::AuthenticatedActionProvider,
                conn: &diesel::pg::PgConnection,
            ) -> Result<crate::types::#id_typename, rocket::http::Status> {
                use crate::types::GetById;

                let entity = crate::types::#typename::get_by_id(self.0, conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.action_provider_id == **auth {
                    Ok(self.0)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_id_for_admin(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;

    let gen = quote! {
        impl crate::types::VerifyIdForAdmin for  crate::types::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_adm(
                self,
                auth: &crate::types::AuthenticatedAdmin,
            ) -> Result<crate::types::#id_typename, rocket::http::Status> {
                Ok(self.0)
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_user_with_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForUserWithDb<#typename> for crate::types::Unverified<#typename> {
            fn verify(
                self,
                auth: &crate::types::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<#typename, rocket::http::Status> {
                use crate::types::GetById;

                let entity = self.0.into_inner();
                if entity.user_id == **auth
                    && #typename::get_by_id(entity.id, conn)
                    .map_err(|_| rocket::http::Status::InternalServerError)?
                    .user_id
                    == **auth
                {
                    Ok(entity)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_user_without_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForUserWithoutDb<#typename> for crate::types::Unverified<#typename> {
            fn verify(
                self,
                auth: &crate::types::AuthenticatedUser,
            ) -> Result<#typename, rocket::http::Status> {
                let entity = self.0.into_inner();
                if entity.user_id == **auth {
                    Ok(entity)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_action_provider_with_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForActionProviderWithDb<#typename> for crate::types::Unverified<#typename> {
            fn verify_ap(
                self,
                auth: &crate::types::AuthenticatedActionProvider,
                conn: &diesel::pg::PgConnection,
            ) -> Result<#typename, rocket::http::Status> {
                use crate::types::GetById;

                let entity = self.0.into_inner();
                if entity.action_provider_id == **auth
                    && #typename::get_by_id(entity.id, conn)
                    .map_err(|_| rocket::http::Status::InternalServerError)?
                    .action_provider_id
                    == **auth
                {
                    Ok(entity)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_action_provider_without_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForActionProviderWithoutDb<#typename> for crate::types::Unverified<#typename> {
            fn verify_ap(
                self,
                auth: &crate::types::AuthenticatedActionProvider,
            ) -> Result<#typename, rocket::http::Status> {
                let entity = self.0.into_inner();
                if entity.action_provider_id == **auth {
                    Ok(entity)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_action_provider_unchecked(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForActionProviderUnchecked<#typename> for crate::types::Unverified<#typename> {
            fn verify_unchecked_ap(
                self,
                auth: &crate::types::AuthenticatedActionProvider,
            ) -> Result<#typename, rocket::http::Status> {
                Ok(self.0.into_inner())
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_admin_without_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForAdminWithoutDb<#typename> for crate::types::Unverified<#typename> {
            fn verify_adm(
                self,
                auth: &crate::types::AuthenticatedAdmin,
            ) -> Result<#typename, rocket::http::Status> {
                Ok(self.0.into_inner())
            }
        }
    };
    gen.into()
}

pub fn impl_from_i32(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;

    let gen = quote! {
        impl crate::types::FromI32 for #id_typename {
            fn from_i32(value: i32) -> Self {
                Self(value)
            }
        }
    };
    gen.into()
}
