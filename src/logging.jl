# TODO: All of this logging stuff might be better handled with multiple dispatch on parametric functions.

# add! a whole structure to the log.
function add!(log::HDF5Logger.Log, slug::String, t::Real, data, n::Int, keep::Bool = false)
    function add_structured!(log, slug, data::T, n, keep) where {T}
        if typeof(data) <: Enum
            # println("I found an enum for " * slug)
            HDF5Logger.add!(log, slug, Base.Enums.basetype(typeof(data))(data), n, keep) # Convert to the base type for the enum.
        elseif isa(data, Tuple)
            @assert isbitstype(eltype(data)) "HDF5Logger doesn't know what to do with a tuple of non-primitive types."
            # println("I found a tuple type for " * slug)
            HDF5Logger.add!(log, slug, [data...,], n, keep) # Convert to an array.
        elseif isa(data, Array)
            @assert isbitstype(eltype(data)) "HDF5Logger doesn't know what to do with an array of non-primitize types."
            # println("I found an array for " * slug)
            HDF5Logger.add!(log, slug, data, n, keep) # HDF5Loggers only know scalars, vectors, and matrices.
        elseif isstructtype(T) # Tuples have to come before this because tuples are struct types?? So are arrays???
            # println("I found a struct type for " * slug)
            for field in fieldnames(typeof(data))
                add_structured!(log, slug * "/" * string(field), getfield(data, field), n, keep)
            end
        elseif isbits(data)
            # println("I found either a bits type or array for " * slug)
            HDF5Logger.add!(log, slug, data, n, keep) # HDF5Loggers only know scalars, vectors, and matrices.
        else
            error("HDF5Logger doesn't know what to do with a " * slug)
        end
    end
    HDF5Logger.add!(log, slug * "time", t, n, keep)
    add_structured!(log, slug * "data", data, n, keep)
end

# log! a whole structure.
function log!(log::HDF5Logger.Log, slug::String, t::Real, data)
    function log_structured!(log, slug, data::T) where {T}
        if typeof(data) <: Enum
            HDF5Logger.log!(log, slug, Base.Enums.basetype(typeof(data))(data)) # Convert to the base type for the enum.
        elseif isa(data, Tuple)
            @assert isbitstype(eltype(data)) "HDF5Logger doesn't know what to do with a tuple of non-primitive types."
            HDF5Logger.log!(log, slug, [data...,]) # Convert to an array.
        elseif isa(data, Array)
            @assert isbitstype(eltype(data)) "HDF5Logger doesn't know what to do with an array of non-primitize types."
            HDF5Logger.log!(log, slug, data)
        elseif isstructtype(T)
            for field in fieldnames(typeof(data))
                log_structured!(log, slug * "/" * string(field), getfield(data, field))
            end
        elseif isbits(data) || (isa(data, Array) && isbitstype(eltype(data)))
            HDF5Logger.log!(log, slug, data)
        else
            error("HDF5Logger doesn't know what to do with a " * slug)
        end
    end
    HDF5Logger.log!(log, slug * "time", t)
    log_structured!(log, slug * "data", data)
end
