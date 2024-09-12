//
//  MTLComputePipelineState+Play.swift
//
//  Copyright © 2024 Robert Guequierre
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Metal

//===------------------------------------------------------------------------===
// MARK: - extension MTLComputePipelineState
//===------------------------------------------------------------------------===

extension MTLComputePipelineState {

    func default2DThreadsPerThreadgroup() -> MTLSize {

        let threadsWidth  = self.threadExecutionWidth
        let threadsHeight = self.maxTotalThreadsPerThreadgroup / threadsWidth

        return .init(width: threadsWidth, height: threadsHeight, depth: 1)
    }

    func defaultImageBlockSize() -> MTLSize {

        //  - All of my devices thus far have had a SIMD group size of 32 - perhaps that assumption,
        //    made explicit here, has crept into places where flexibility is called for instead,
        //    so set traps for myself
        precondition( 32 == self.threadExecutionWidth && 32*16 <= self.maxTotalThreadsPerThreadgroup )

        return .init( width: 32, height: (self.maxTotalThreadsPerThreadgroup < 1024) ? 16 : 32,
                      depth:  1 )
    }

    func simdGroup1DThreadsSize() -> MTLSize {

        //  - All of my devices thus far have had a SIMD group size of 32 - perhaps that assumption,
        //    made explicit here, has crept into places where flexibility is called for instead,
        //    so set traps for myself
        assert( 32 == self.threadExecutionWidth )

        return .init(width: self.threadExecutionWidth, height: 1, depth: 1)
    }
}
