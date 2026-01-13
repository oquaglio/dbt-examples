select
  id,
  first_name,
  last_name,
  email,
  phone,
  ssn
from {{ ref('sample_customers') }}
