"""
    Utils.Validation

Module for input validation with schemas and custom validators.
Provides the @validate macro for type-safe validation.
"""

module Validation

export @validate, Validator, required, email, min_length, max_length, matches, in_list
export validate, validate_data, ValidationError

# Re-export ValidationError from ErrorHandler
include("../Utils/ErrorHandler.jl")
using .ErrorHandler: ValidationError

# ============================================================================
# Validator Type
# ============================================================================

"""
    Validator

A validator function that checks a value and returns (is_valid::Bool, error_message::String).
"""
const Validator = Function

# ============================================================================
# Built-in Validators
# ============================================================================

"""
    required(field_name::String="field")::Validator

Validates that value is not nothing, empty string, or empty collection.
"""
function required(field_name::String="field")::Validator
    return function(value)
        if value === nothing || value == "" || (isa(value, AbstractVector) && isempty(value))
            return false, "$field_name is required"
        end
        return true, ""
    end
end

"""
    email()::Validator

Validates that value is a valid email address.
"""
function email()::Validator
    email_regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return function(value)
        if !isa(value, String) || !occursin(email_regex, value)
            return false, "must be a valid email address"
        end
        return true, ""
    end
end

"""
    min_length(min::Int)::Validator

Validates that value has minimum length.
"""
function min_length(min::Int)::Validator
    return function(value)
        if !isa(value, Union{String, AbstractVector})
            return false, "must be a string or collection"
        end
        if length(value) < min
            return false, "must have at least $min characters"
        end
        return true, ""
    end
end

"""
    max_length(max::Int)::Validator

Validates that value has maximum length.
"""
function max_length(max::Int)::Validator
    return function(value)
        if !isa(value, Union{String, AbstractVector})
            return false, "must be a string or collection"
        end
        if length(value) > max
            return false, "must have at most $max characters"
        end
        return true, ""
    end
end

"""
    matches(pattern::Regex)::Validator

Validates that string matches given regex pattern.
"""
function matches(pattern::Regex)::Validator
    return function(value)
        if !isa(value, String) || !occursin(pattern, value)
            return false, "invalid format"
        end
        return true, ""
    end
end

"""
    in_list(valid_values::Vector)::Validator

Validates that value is in the list of allowed values.
"""
function in_list(valid_values::Vector)::Validator
    return function(value)
        if value ∉ valid_values
            return false, "must be one of: $(join(valid_values, ", "))"
        end
        return true, ""
    end
end

# ============================================================================
# Validation Functions
# ============================================================================

"""
    validate(field_name::String, value, validators::Vector{Validator})::Tuple{Bool, String}

Validate a single field against multiple validators.
Returns (is_valid, error_message).
"""
function validate(field_name::String, value, validators::Vector{Validator})::Tuple{Bool, String}
    for validator in validators
        is_valid, error_msg = validator(value)
        if !is_valid
            return false, error_msg
        end
    end
    return true, ""
end

"""
    validate_data(data::Dict, schema::Dict)::Tuple{Bool, Dict{String, String}}

Validate data against a schema.
Schema format: Dict("field_name" => Vector{Validator})

Returns (is_valid, errors_dict).
"""
function validate_data(data::Dict, schema::Dict)::Tuple{Bool, Dict{String, String}}
    errors = Dict{String, String}()
    
    for (field_name, validators) in schema
        value = get(data, field_name, nothing)
        is_valid, error_msg = validate(field_name, value, validators)
        
        if !is_valid
            errors[field_name] = error_msg
        end
    end
    
    return isempty(errors), errors
end

# ============================================================================
# @validate Macro
# ============================================================================

"""
    @validate(data::Dict, schema::Dict)

Macro for convenient validation that throws ValidationError on failure.

# Examples
```julia
using Nova.Validation

schema = Dict(
    "email" => [required("email"), email()],
    "password" => [required("password"), min_length(8), max_length(128)],
    "age" => [required("age"), in_list([18, 21, 25])]
)

data = Dict("email" => "user@example.com", "password" => "secure123", "age" => 21)

@validate data schema  # Passes silently

# If validation fails, throws ValidationError
data_invalid = Dict("email" => "invalid", "password" => "123")
@validate data_invalid schema  # Throws ValidationError
```
"""
macro validate(data, schema)
    quote
        is_valid, errors = validate_data($(esc(data)), $(esc(schema)))
        
        if !is_valid
            # Find first error and throw
            first_field = first(keys(errors))
            first_error = errors[first_field]
            throw(ValidationError(first_field, first_error))
        end
    end
end

"""
    @validate_one(field_name::String, value, validators::Vector)

Macro for validating a single field.

# Examples
```julia
@validate_one("email", "user@example.com", [required("email"), email()])
```
"""
macro validate_one(field_name, value, validators)
    quote
        is_valid, error_msg = validate($(esc(field_name)), $(esc(value)), $(esc(validators)))
        
        if !is_valid
            throw(ValidationError($(esc(field_name)), error_msg))
        end
    end
end

end # module Validation
