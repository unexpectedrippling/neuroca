
soft_threshold <- function(x,d) return(sign(x)*pmax(0, abs(x)-d))


prox <- function(X, u, Lu, v, Su, lambda, conv=1e-5) {
  u0 <- u
  crit <- Inf
  while (crit > conv) {
    ut <- u + 1/Lu * (X %*% v - Su %*% u)
    ut <- soft_threshold(ut, lambda/Lu)
    crit <- sum( (ut - u)^2)
    u <- ut
  }
  
  u
}

sfpca <- function(X, lu=1, lv=1, au=1, av=1, coords, Pu=NULL, Pv=NULL, conv=1e-5) {
  
  if (is.null(Pv)) {
    Pv <- neighborweights::spatial_laplacian(coords, nnk=ncol(coords)^2, weight_mode="binary")
  }
  
  Sv <- Matrix::Diagonal(n=ncol(X)) + av*Pv
  Lv <- RSpectra::eigs(Sv,1)$values

  if (is.null(Pu)) {
    Pu <- neighborweights::temporal_laplacian(1:nrow(X))
  }
  
  Su <- Matrix::Diagonal(n=nrow(X)) + au*Pu
  Lu <- RSpectra::eigs(Su,1)$values
  
  init_svd <- RSpectra::svds(X, 1)
  v <- init_svd$v
  u <- init_svd$u
  criterion <- Inf
  while (criterion > conv) {
    u_new <- prox(X, u, Lu, v, Su, lu)
    v_new <- prox(t(X), v, Lv, u, Sv, lv)
    
    v_new <- v_new/sqrt(t(v_new) %*% Sv %*% v_new)[1,1]
    u_new <- u_new/sqrt(t(u_new) %*% Su %*% u_new)[1,1]
    
    criterion <- max(sum( (v_new - v)^2), sum((u_new - u)^2))
    print(criterion)
    u <- u_new
    v <- v_new
  }
  
  v <- v/sum(v^2)
  u <- u/sum(u^2)
  
  
  ##Ou <- 
}