


#' @keywords internal
get_block_indices <- function(Xlist) {
  ncols <- sapply(Xlist, ncol)
  csum <- cumsum(ncols)
  csum1 <- c(0, csum[-length(csum)])
  m <- as.matrix(cbind(csum1+1, csum))
  colnames(m) <- c("start", "end")
  m
}




#' block_matrix_list
#' 
#' @param Xs a list of k matrices each with with N_k rows and M_k columns 
#' @export
#' @importFrom assertthat assert_that
block_matrix_list <- function(Xs) {
  assertthat::assert_that(all(sapply(Xs, is.matrix)))
  assertthat::assert_that(all(sapply(Xs, nrow) == nrow(Xs[[1]])))
  
  blockInd <- block_indices(Xs)
  P <- sum(sapply(Xs, ncol))
  
  attr(Xs, "block_indices") <- blockInd
  attr(Xs, "nblock") <- length(Xs)
  attr(Xs, "nrow") <- nrow(Xs[[1]])
  attr(Xs, "ncol") <- P
  attr(Xs, "block_names") <- names(Xs)
  class(Xs) <- c("block_matrix_list", "block_matrix", "list") 
  
  Xs
}

#' @export
to_block_matrix <- function(X, block_lengths) {
  if (is.data.frame(X)) {
    X <- as.matrix(X)
  }
  
  assertthat::assert_that(sum(block_lengths) == ncol(X))
  
  csum <- cumsum(block_lengths)
  csum1 <- c(0, csum[-length(csum)])
  m <- as.matrix(cbind(csum1+1, csum))
  colnames(m) <- c("start", "end")
  blockInd <- m
  
  attr(X, "block_indices") <- blockInd
  attr(X, "nblock") <- length(block_lengths)
  attr(X, "block_names") <- paste0("B", 1:length(block_lengths))
  class(X) <- c("block_matrix", "matrix") 
  
  X
  
}


#' block_matrix
#' 
#' @param Xs a list of k matrices with N rows and M_k columns 
#' @export
#' @importFrom assertthat assert_that
block_matrix <- function(Xs) {
  assertthat::assert_that(all(sapply(Xs, is.matrix)))
  assertthat::assert_that(all(sapply(Xs, nrow) == nrow(Xs[[1]])))
  
  blockInd <- get_block_indices(Xs)
  P <- sum(sapply(Xs, ncol))
  
  X <- do.call(cbind, Xs)
  attr(X, "block_indices") <- blockInd
  attr(X, "nblock") <- length(Xs)
  attr(X, "block_names") <- names(Xs)
  class(X) <- c("block_matrix", "matrix") 
  
  X
}


#' @export
matrix_to_block_matrix <- function(X, groups) {
  assert_that(length(groups) == ncol(X))
  glevs <- sort(unique(groups))
  Xlist <- lapply(glevs, function(i) {
    idx <- which(groups==i)
    x <- X[, idx]
  })
  
  block_matrix(Xlist)
}

#' @export
nrow.block_matrix_list <- function(x) {
  attr(x, "nrow")
  
}

#' @export
ncol.block_matrix_list <- function(x) {
  attr(x, "ncol")
}


#' @export
dim.block_matrix_list <- function(x) {
  c(attr(x, "nrow"), attr(x, "ncol"))
}


#' @export
block_lengths.block_matrix <- function(object) {
  bind <- attr(object, "block_indices")
  apply(bind, 1, diff)+1
}

#' @export
block_index_list.block_matrix <- function(object) {
  bind <- attr(object, "block_indices")
  lapply(1:nrow(bind), function(i) seq(bind[i,1], bind[i,2]))
}




#' @export
get_block.block_matrix <- function(x, i,...) {
  ind <- attr(x, "block_indices")
  x[, seq(ind[i,1], ind[i,2]) ]
}

#' @export
get_block.block_matrix_list <- function(x, i) {
  x[[i]]
}


#' @export
as.list.block_matrix <- function(x) {
  lapply(1:attr(x, "nblock"), function(i) get_block(x, i))
}

#' @export
as.list.block_matrix_list <- function(x) {
  x
}

#' @export
as.matrix.block_matrix_list <- function(x) {
  block_matrix(x)
}


#' @export
nblocks.block_matrix <- function(x) {
  attr(x, "nblock")
}


#' @export
rbind.block_matrix <- function(...) {
  mlist <- list(...)
  nb <- unlist(lapply(mlist, nblocks))
  
  assert_that(all(nb[1] == nb))
  res <- lapply(1:nb[1], function(bnum) {
    do.call(rbind, lapply(mlist, function(x) get_block(x, bnum)))
  })

  block_matrix(res)
}

#' @export
block_apply.block_matrix <- function(x, f) {
  ret <- lapply(1:nblocks(x), function(i) {
    f(get_block(x,i), i)
  })
  
  block_matrix_list(ret)
}

#' @export
names.block_matrix <- function(x) attr(x, "block_names")

#' @export
is.block_matrix <- function(x) { inherits(x, "block_matrix") }

#t.block_matrix <- function(x) {
#  browser()
#}

#' @export
print.block_matrix <- function(object) {
  bind <- attr(object, "block_indices")
  
  cat("block_matrix", "\n")
  cat("  nblocks: ", attr(object, "nblock"), "\n")
  cat("  nrows: ", nrow(object), "\n")
  cat("  ncols: ", ncol(object), "\n")
  cat("  block cols: ", apply(bind, 1, diff)+1, "\n")
  cat("  block names: ", attr(object, "block_names"))
}







