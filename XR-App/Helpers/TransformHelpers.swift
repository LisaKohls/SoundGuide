//
//  TransformHelpers.swift
//  XR-App
//
//  Created by GuitAR on 12.05.25.
//


import simd
import RealityKit

public extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension Transform {
    var translation: SIMD3<Float> {
        return self.matrix.columns.3.xyz
    }
}

extension simd_float4 {
    var xyz: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }
}
