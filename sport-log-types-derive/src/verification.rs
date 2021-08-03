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
        impl crate::VerifyIdForUser for crate::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Self::Id, rocket::http::Status> {
                use crate::GetById;

                let entity = crate::#typename::get_by_id(self.0, conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entity.user_id == **auth {
                    Ok(self.0)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }

        impl crate::VerifyMultipleIdForUser for crate::UnverifiedIds<#id_typename> {
            type Id = #id_typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Id>, rocket::http::Status> {
                use crate::GetByIds;

                let entities = crate::#typename::get_by_ids(&self.0, conn)
                    .map_err(|_| rocket::http::Status::Forbidden)?;
                if entities.iter().all(|entity| entity.user_id == **auth ){
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
        impl crate::VerifyIdForUserUnchecked for crate::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_unchecked(
                self,
                auth: &crate::AuthenticatedUser,
            ) -> Result<crate::#id_typename, rocket::http::Status> {
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
        impl crate::VerifyIdForActionProvider for crate::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_ap(
                self,
                auth: &crate::AuthenticatedActionProvider,
                conn: &diesel::pg::PgConnection,
            ) -> Result<crate::#id_typename, rocket::http::Status> {
                use crate::GetById;

                let entity = crate::#typename::get_by_id(self.0, conn)
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
        impl crate::VerifyIdForAdmin for crate::UnverifiedId<#id_typename> {
            type Id = #id_typename;

            fn verify_adm(
                self,
                auth: &crate::AuthenticatedAdmin,
            ) -> Result<crate::#id_typename, rocket::http::Status> {
                Ok(self.0)
            }
        }

        impl crate::VerifyMultipleIdForAdmin for crate::UnverifiedIds<#id_typename> {
            type Id = #id_typename;

            fn verify_adm(
                self,
                auth: &crate::AuthenticatedAdmin,
            ) -> Result<Vec<crate::#id_typename>, rocket::http::Status> {
                Ok(self.0)
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_user_with_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForUserWithDb for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Self::Entity, rocket::http::Status> {
                use crate::GetById;

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

        impl crate::VerifyMultipleForUserWithDb for crate::Unverified<Vec<#typename>> {
            type Entity = #typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Vec<Self::Entity>, rocket::http::Status> {
                use crate::GetById;

                let entities = self.0.into_inner();

                let mut valid = true;
                for entity in &entities {
                    if entity.user_id == **auth
                        && #typename::get_by_id(entity.id, conn)
                        .map_err(|_| rocket::http::Status::InternalServerError)?
                        .user_id
                        == **auth {
                        valid = false;
                    }
                }
                if valid
                {
                    Ok(entities)
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
        impl crate::VerifyForUserWithoutDb for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
            ) -> Result<Self::Entity, rocket::http::Status> {
                let entity = self.0.into_inner();
                if entity.user_id == **auth {
                    Ok(entity)
                } else {
                    Err(rocket::http::Status::Forbidden)
                }
            }
        }

        impl crate::VerifyMultipleForUserWithoutDb for crate::Unverified<Vec<#typename>> {
            type Entity = #typename;

            fn verify(
                self,
                auth: &crate::AuthenticatedUser,
            ) -> Result<Vec<Self::Entity>, rocket::http::Status> {
                let entities = self.0.into_inner();
                if entities.iter().all(|entity| entity.user_id == **auth) {
                    Ok(entities)
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
        impl crate::VerifyForActionProviderWithDb for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify_ap(
                self,
                auth: &crate::AuthenticatedActionProvider,
                conn: &diesel::pg::PgConnection,
            ) -> Result<Self::Entity, rocket::http::Status> {
                use crate::GetById;

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
        impl crate::VerifyForActionProviderWithoutDb for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify_ap(
                self,
                auth: &crate::AuthenticatedActionProvider,
            ) -> Result<Self::Entity, rocket::http::Status> {
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
        impl crate::VerifyForActionProviderUnchecked for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify_unchecked_ap(
                self,
                auth: &crate::AuthenticatedActionProvider,
            ) -> Result<Self::Entity, rocket::http::Status> {
                Ok(self.0.into_inner())
            }
        }
    };
    gen.into()
}

pub fn impl_verify_for_admin_without_db(ast: &syn::DeriveInput) -> TokenStream {
    let typename = &ast.ident;

    let gen = quote! {
        impl crate::VerifyForAdminWithoutDb for crate::Unverified<#typename> {
            type Entity = #typename;

            fn verify_adm(
                self,
                auth: &crate::AuthenticatedAdmin,
            ) -> Result<Self::Entity, rocket::http::Status> {
                Ok(self.0.into_inner())
            }
        }

        impl crate::VerifyMultipleForAdminWithoutDb for crate::Unverified<Vec<#typename>> {
            type Entity = #typename;

            fn verify_adm(
                self,
                auth: &crate::AuthenticatedAdmin,
            ) -> Result<Vec<Self::Entity>, rocket::http::Status> {
                Ok(self.0.into_inner())
            }
        }
    };
    gen.into()
}

pub fn impl_from_i32(ast: &syn::DeriveInput) -> TokenStream {
    let id_typename = &ast.ident;

    let gen = quote! {
        impl crate::FromI32 for #id_typename {
            fn from_i32(value: i32) -> Self {
                Self(value)
            }
        }
    };
    gen.into()
}
