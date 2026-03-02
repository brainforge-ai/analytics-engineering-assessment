-- TODO: Implement staging model for customers.
-- Handle duplicate emails per CHALLENGE.md sect 3.1.
-- Replace the pass-through below with your implementation.

select * from {{ ref('customers') }}
