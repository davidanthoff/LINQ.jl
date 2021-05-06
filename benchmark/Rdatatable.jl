module Rdatatable

using StatsBase, RCall, Query, DataFrames, DataFramesMeta, DataTables
using IndexedTables
using IndexedTables.Table

function R_datatable(N, K)

    R"""
    library(data.table)
    N <- $N
    K <- $K
    # copied from
    # https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping
    set.seed(1)
    DT <- data.table(
      id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
      id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
      id3 = sample(sprintf("id%010d",1:(N/K)), N, TRUE), # small groups (char)
      id4 = sample(K, N, TRUE),                          # large groups (int)
      id5 = sample(K, N, TRUE),                          # large groups (int)
      id6 = sample(N/K, N, TRUE),                        # small groups (int)
      v1 =  sample(5, N, TRUE),                          # int in range [1,5]
      v2 =  sample(5, N, TRUE),                          # int in range [1,5]
      v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
    )

    timings <- list()

    timings$sum1 <- system.time( DT[, sum(v1), keyby=id1] )[3]
    timings$sum2 <- system.time( DT[, sum(v1), keyby=id1] )[3]
    timings$sum3 <- system.time( DT[, sum(v1), keyby="id1,id2"] )[3]
    timings$sum4 <- system.time( DT[, sum(v1), keyby="id1,id2"] )[3]
    timings$sum_mean1 <- system.time( DT[, list(sum(v1),mean(v3)), keyby=id3] )[3]
    timings$sum_mean2 <- system.time( DT[, list(sum(v1),mean(v3)), keyby=id3] )[3]
    timings$mean7_9_by_id4_1 <- system.time( DT[, lapply(.SD, mean), keyby=id4, .SDcols=7:9] )[3]
    timings$mean7_9_by_id4_2 <- system.time( DT[, lapply(.SD, mean), keyby=id4, .SDcols=7:9] )[3]
    timings$sum7_9_by_id6_1 <- system.time( DT[, lapply(.SD, sum), keyby=id6, .SDcols=7:9] )[3]
    timings$sum7_9_by_id6_2 <- system.time( DT[, lapply(.SD, sum), keyby=id6, .SDcols=7:9] )[3]
    """
    @rget timings
    return timings
end


function R_dplyr(N, K)

    R"""
    library(dplyr)
    N <- $N
    K <- $K
    # copied from
    # https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping
    set.seed(1)
    DF <- data.frame(
      id1 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
      id2 = sample(sprintf("id%03d",1:K), N, TRUE),      # large groups (char)
      id3 = sample(sprintf("id%010d",1:(N/K)), N, TRUE), # small groups (char)
      id4 = sample(K, N, TRUE),                          # large groups (int)
      id5 = sample(K, N, TRUE),                          # large groups (int)
      id6 = sample(N/K, N, TRUE),                        # small groups (int)
      v1 =  sample(5, N, TRUE),                          # int in range [1,5]
      v2 =  sample(5, N, TRUE),                          # int in range [1,5]
      v3 =  sample(round(runif(100,max=100),4), N, TRUE) # numeric e.g. 23.5749
    )

    timings <- list()

    timings$sum1             <- system.time( DF %>% group_by(id1) %>% summarise(sum(v1)) )[3]
    timings$sum2             <- system.time( DF %>% group_by(id1) %>% summarise(sum(v1)) )[3]
    timings$sum3             <- system.time( DF %>% group_by(id1,id2) %>% summarise(sum(v1)) )[3]
    timings$sum4             <- system.time( DF %>% group_by(id1,id2) %>% summarise(sum(v1)) )[3]
    timings$sum_mean1        <- system.time( DF %>% group_by(id3) %>% summarise(sum(v1),mean(v3)) )[3]
    timings$sum_mean2        <- system.time( DF %>% group_by(id3) %>% summarise(sum(v1),mean(v3)) )[3]
    timings$mean7_9_by_id4_1 <- system.time( DF %>% group_by(id4) %>% summarise_at(c("v1","v2","v3"),mean) )[3]
    timings$mean7_9_by_id4_2 <- system.time( DF %>% group_by(id4) %>% summarise_at(c("v1","v2","v3"),mean) )[3]
    timings$sum7_9_by_id6_1  <- system.time( DF %>% group_by(id6) %>% summarise_at(c("v1","v2","v3"),sum) )[3]
    timings$sum7_9_by_id6_2  <- system.time( DF %>% group_by(id6) %>% summarise_at(c("v1","v2","v3"),sum) )[3]
    """
    @rget timings
    return timings
end

function createDataFrame(N::Int, K::Int)

    df = DataFrame(id1=sample(["id$x" for x in 1:K], N),
                   id2=sample(["id$x" for x in 1:K], N),
                   id3=sample(["id$x" for x in 1:(N / K)], N),
                   id4=sample(1:K, N),
                   id5=sample(1:K, N),
                   id6=sample(1:(N / K), N),
                   v1=sample(1:5, N),
                   v2=sample(1:5, N),
                   v3=sample(round.(rand(100), 4), N))

    return df
end

function createDataTable(N::Int, K::Int)

    df = DataTable(id1=sample(["id$x" for x in 1:K], N),
                   id2=sample(["id$x" for x in 1:K], N),
                   id3=sample(["id$x" for x in 1:(N / K)], N),
                   id4=sample(1:K, N),
                   id5=sample(1:K, N),
                   id6=sample(1:(N / K), N),
                   v1=sample(1:5, N),
                   v2=sample(1:5, N),
                   v3=sample(round.(rand(100), 4), N))

    return df
end
function createIndexedTable(N::Int, K::Int)

    df = Table(Columns(id1=sample(["id$x" for x in 1:K], N),
                   id2=sample(["id$x" for x in 1:K], N),
                   id3=sample(["id$x" for x in 1:(N / K)], N),
                   id4=sample(1:K, N),
                   id5=sample(1:K, N),
                   id6=sample(1:(N / K), N),
                   v1=sample(1:5, N),
                   v2=sample(1:5, N),
                   v3=sample(round.(rand(100), 4), N)))

    return df
end

function benches(df::DataFrame)

    #  timings
    ti = Dict()

    ti[:sum1] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum2] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum3] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum4] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum_mean1] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum_mean2] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_1] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_2] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_1] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_2] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    return ti
end
function benches(df::DataTable)

    #  timings
    ti = Dict()

    ti[:sum1] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum2] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum3] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum4] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum_mean1] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum_mean2] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_1] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_2] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_1] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_2] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    return ti
end
function benches(df::IndexedTable)

    #  timings
    ti = Dict()

    ti[:sum1] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum2] = @elapsed @from i in df begin
                             @group i by i.id1 into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum3] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum4] = @elapsed @from i in df begin
                             @group i by (i.id1, i.id2) into g
                             @select {r = sum(g.v1)}
                             @collect DataFrame
                         end
    ti[:sum_mean1] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum_mean2] = @elapsed @from i in df begin
                             @group i by i.id3 into g
                             @select {s = sum(g.v1),m = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_1] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:mean7_9_by_id4_2] = @elapsed @from i in df begin
                             @group i by i.id4 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_1] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    ti[:sum7_9_by_id6_2] = @elapsed @from i in df begin
                             @group i by i.id6 into g
                             @select {m7 = mean(g.v1),m8 = mean(g.v2),m9 = mean(g.v3)}
                             @collect DataFrame
                         end
    return ti
end

function DfMeta_benches(df::DataFrame)

    #  timings
    ti = Dict()

    ti[:sum1] = @elapsed @linq df |>
                    @by(:id1,r = sum(:v1))

    ti[:sum2] = @elapsed @linq df |>
                    @by(:id1,r = sum(:v1))

    ti[:sum3] = @elapsed @linq df |>
                    @by([:id1,:id2],r = sum(:v1))

    ti[:sum4] = @elapsed @linq df |>
                    @by([:id1,:id2],r = sum(:v1))

    ti[:sum_mean1] = @elapsed @linq df |>
                    @by(:id3,s = sum(:v1),m = mean(:v1))

    ti[:sum_mean2] = @elapsed @linq df |>
                    @by(:id3,s = sum(:v1),m = mean(:v1))

    ti[:mean7_9_by_id4_1] = @elapsed @linq df |>
                        @by(:id4,m7 = mean(:v1),m8 = mean(:v2),m9 = mean(:v3))

    ti[:mean7_9_by_id4_2] = @elapsed @linq df |>
                        @by(:id4,m7 = mean(:v1),m8 = mean(:v2),m9 = mean(:v3))

    ti[:sum7_9_by_id6_1] = @elapsed @linq df |>
                        @by(:id6,m7 = mean(:v1),m8 = mean(:v2),m9 = mean(:v3))

    ti[:sum7_9_by_id6_2] = @elapsed @linq df |>
                        @by(:id6,m7 = mean(:v1),m8 = mean(:v2),m9 = mean(:v3))

    return ti
end

function run_benches(N=1_000_000;K=100)
    # get small data for JIT warmup
    d_ = createDataFrame(10, 3)
    dt_ = createDataTable(10, 3)
    di_ = createIndexedTable(10, 3)


    #  warm up julia benchmarks
    benches(d_);
    benches(dt_);
    benches(di_);
    DfMeta_benches(d_);

    #  get real data
    d = createDataFrame(N, K)
    # measure DataFrames
    query_df = benches(d)
    meta = DfMeta_benches(d)
    d = 0
    gc()
    # measure DataTables
    dt = createDataTable(N, K)
    query_dt = benches(dt)
    dt = 0
    gc()
    # measure IndexedTables
    di = createIndexedTable(N, K)
    query_di = benches(di)
    di = 0
    gc()


    # get R data.table time
    R = R_datatable(N, K)

    # get R dplyr time
    Rdplyr = R_dplyr(N, K)

    # get
    k = collect(keys(query_df))
    out = DataFrame(bench=k, Query_DF=[query_df[kk] for kk in k], Query_DT=[query_dt[kk] for kk in k], Query_idxT=[query_di[kk] for kk in k], DataFramesMeta=[meta[kk] for kk in k], Rdplyr=[Rdplyr[kk] for kk in k], Rdatatable=[R[kk] for kk in k])
    sort!(out, cols=:bench)
    rel = deepcopy(out)
    rel = @transform(rel,Query_DF = :Query_DF ./ :Rdatatable, Query_DT = :Query_DT ./ :Rdatatable, Query_idxT = :Query_idxT ./ :Rdatatable, DataFramesMeta = :DataFramesMeta ./ :Rdatatable, Rdplyr = :Rdplyr ./ :Rdatatable, Rdatatable = 1.0)
    return (out, rel)
end

function run_all()
    d = Dict()
    for n in [10_000, 100_000, 1_000_000, 2_000_000]
        d[n] = run_benches(n)
        gc()
        info("results with $n rows:")
        info("-- absolute time in seconds:")
        println(d[n][1])
        info("-- time relative to R data.table:")
        println(d[n][2])
        println()
        println()
    end
    return d
end
end # module
