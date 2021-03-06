#' Deprecated calibration method (without the support of custom column name)
# calibrateBatch.intra.rlm.old <- function(data = ...,
#                                      intensity = intensity,
#                                      injection_sequence = injection_sequence) {
#     intensity <- data %>% dplyr::pull(intensity)
#     injection_sequence <- data %>% dplyr::pull(injection_sequence)
#     rlm <- MASS::rlm(intensity ~ injection_sequence)
#     rlm_summary <- rlm %>% summary
#     slope <- rlm_summary[["coefficients"]][2, 1]
#     intercept <- rlm_summary[["coefficients"]][1, 1]
#     # calibration center
#     center_injec_seq <- length(injection_sequence)/2
#     center_intensity <- center_injec_seq * slope + intercept
#     # calibrted data
#     intensity_calibration <- rlm_summary[["residuals"]] + center_intensity
#     calibrated_data <- data.frame(intensity_intra_calibrated = intensity_calibration, injection_sequence)
#     return(calibrated_data)
# }



#' Intra batch calibration by robust linear modeling - one feature (rlm)
#'
#' @param data Metabolomics data in long-format
#' @param intensity The column name of intensity (by default intensity)
#' @param injection_sequence The column name of injection sequence (by default injection_sequence)
#' @example
#' data.frame(intensity = runif(50, min=10, max=50), injection_sequence = 1:50) %>% libra::calibrateBatch.intra.rlm()
calibrateBatch.intra.rlm <- function(data = ...,
                                     intensity = intensity,
                                     injection_sequence = injection_sequence,
                                     feature = feature){

    intensity <- rlang::enexpr(intensity)
    injection_sequence <- rlang::enexpr(injection_sequence)
    feature <- rlang::enexpr(feature)

    data_n <- data %>% dplyr::group_by(!! feature) %>% tidyr::nest()
    data_n_c <- data_n %>%
        dplyr::mutate(data_calibrated = purrr::map(data, calibrateBatch.intra.rlm.single.feature, intensity = !!intensity, injection_sequence = !! injection_sequence)) %>%
        dplyr::select(-data) %>% tidyr::unnest(cols = c(data_calibrated))
    return(data_n_c)
}

calibrateBatch.intra.rlm.group <- function(data = ...,
                                           intensity = intensity,
                                           injection_sequence = injection_sequence,
                                           feature = feature,
                                           group = ...){

    intensity <- rlang::enexpr(intensity)
    injection_sequence <- rlang::enexpr(injection_sequence)
    feature <- rlang::enexpr(feature)
    group_factor <- rlang::enexpr(group)

    # variable checking ---------
    if( data %>% pull(!! group_factor) %>% is.na() %>% any() ) stop("group factor must not contain NA")

    # ---------------------------

    data_n <- data %>% dplyr::group_by(!! feature, !! group_factor) %>% tidyr::nest()
    data_n_c <- data_n %>%
        dplyr::mutate(data_calibrated = purrr::map(data, calibrateBatch.intra.rlm.single.feature,
                                                   intensity = !!intensity, injection_sequence = !! injection_sequence)) %>%
        dplyr::select(-data) %>% tidyr::unnest(cols = c(data_calibrated)) %>% dplyr::select(feature, drink, intensity, intensity_intra_calibrated)
    return(data_n_c)
}


calibrateBatch.intra.rlm.single.feature <- function(data = ...,
                                                    intensity = intensity,
                                                    injection_sequence = injection_sequence){

    intensity <- rlang::enexpr(intensity)
    injection_sequence <- rlang::enexpr(injection_sequence)

    # intensity. <- data %>% dplyr::pull(!!intensity)
    # injection_sequence. <- data %>% dplyr::pull(!!injection_sequence)
    data <- data %>% mutate(dummy_injection_sequence = 0: (nrow(.)-1))
    rlm <- MASS::rlm(intensity ~ dummy_injection_sequence, data)
    calibrated_data <- rlm %>% broom::augment() %>% mutate(intensity_intra_calibrated = .resid + .fitted[round(nrow(.)/2)],
                                                           intensity_intra_calibrated = ifelse(intensity_intra_calibrated < 0 , !! intensity , intensity_intra_calibrated)) %>% select(intensity_intra_calibrated)
    # calibrted data
    return(calibrated_data)
}

calibrateBatch.intra.ar1 <- function(data = ...) {
    intensity <- data %>% dplyr::pull(intensity)
    injection_sequence <- data %>% pull(injection_sequence)
    rlm <- MASS::rlm(intensity ~ injection_sequence)
    rlm_summary <- rlm %>% summary
    slope <- rlm_summary[["coefficients"]][2, 1]
    intercept <- rlm_summary[["coefficients"]][1, 1]
    # calibration center
    center_injec_seq <- length(injection_sequence)/2
    center_intensity <- center_injec_seq * slope + intercept
    # calibrted data
    intensity_calibration <- rlm_summary[["residuals"]] + center_intensity
    calibrated_data <- data.frame(intensity_calibrated = intensity_calibration, injection_sequence)
    return(calibrated_data)
}
