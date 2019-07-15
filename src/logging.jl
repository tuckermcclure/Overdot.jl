# add! a whole structure to the log.
function add!(log::HDF5Logger.Log, slug::String, t::Real, data, n::Int, keep::Bool = false)
    function add_structured!(log, slug, data, n, keep)
        if typeof(data) <: Enum
            HDF5Logger.add!(log, slug, Base.Enums.basetype(typeof(data))(data), n, keep) # HDF5Loggers only know scalars, vectors, and matrices.
        elseif isbits(data) || (isa(data, Array) && isbitstype(eltype(data)))
            HDF5Logger.add!(log, slug, data, n, keep) # HDF5Loggers only know scalars, vectors, and matrices.
        else
            for field in fieldnames(typeof(data))
                add_structured!(log, slug * "/" * string(field), getfield(data, field), n, keep)
            end
        end
    end
    HDF5Logger.add!(log, slug * "time", t, n, keep)
    add_structured!(log, slug * "data", data, n, keep)
end

# log! a whole structure.
function log!(log::HDF5Logger.Log, slug::String, t::Real, data)
    function log_structured!(log, slug, data)
        if typeof(data) <: Enum
            HDF5Logger.log!(log, slug, Base.Enums.basetype(typeof(data))(data))
        elseif isbits(data) || (isa(data, Array) && isbitstype(eltype(data)))
            HDF5Logger.log!(log, slug, data)
        else
            for field in fieldnames(typeof(data))
                log_structured!(log, slug * "/" * string(field), getfield(data, field))
            end
        end
    end
    HDF5Logger.log!(log, slug * "time", t)
    log_structured!(log, slug * "data", data)
end
