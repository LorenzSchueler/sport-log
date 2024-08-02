use derive_deftly::define_derive_deftly;

define_derive_deftly! {
    /// Derives `TryFrom<IdString>` and `Into<IdString>`.
    ///
    /// This macro only works if the type is a tuple struct with a single field of type `i64`.
    IdString for struct:

    impl TryFrom<$crate::types::IdString> for $ttype {
        type Error = <i64 as std::str::FromStr>::Err;

        fn try_from(id_string: IdString) -> Result<Self, Self::Error> {
            id_string.0.parse().map(Self)
        }
    }

    #[allow(clippy::from_over_into)]
    impl Into<crate::types::IdString> for $ttype {
        fn into(self) -> crate::types::IdString {
            crate::types::IdString(self.0.to_string())
        }
    }
}

#[cfg(feature = "db")]
define_derive_deftly! {
    /// Derives `diesel::types::ToSql<diesel::sql_types::BigInt, diesel::pg::Pg>`.
    ///
    /// This macro only works if the type is a tuple struct with a single field of type `i64`.
    IntoPgBigInt for struct:

    impl diesel::serialize::ToSql<diesel::sql_types::BigInt, diesel::pg::Pg> for $ttype {
        fn to_sql<'b>(&'b self, out: &mut diesel::serialize::Output<'b, '_, diesel::pg::Pg>) -> diesel::serialize::Result {
            diesel::serialize::ToSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::to_sql(&self.0, out)
        }
    }
}

#[cfg(feature = "db")]
define_derive_deftly! {
    /// Derives `diesel::types::IdFromSql<diesel::sql_types::BigInt,
    /// diesel::pg::Pg>`.
    ///
    /// This macro only works if the type is a tuple struct with a single field of type `i64`.
    FromPgBigInt for struct:

    impl diesel::deserialize::FromSql<diesel::sql_types::BigInt, diesel::pg::Pg> for $ttype {
        fn from_sql(bytes: <diesel::pg::Pg as diesel::backend::Backend>::RawValue<'_>) -> diesel::deserialize::Result<Self> {
            let id = diesel::deserialize::FromSql::<diesel::sql_types::BigInt, diesel::pg::Pg>::from_sql(bytes)?;
            Ok(Self(id))
        }
    }
}
