import OSLog

import DokoTypes
import DokoLogging
import DokoPacketManager

extension DokoStateEngine {
  public func createScheduler(schedules: StateEngineDokoSchedule) -> Task<Void, Never>? {
    Task {
      defer {
        self.logger.debug("\(timestamp()) SE.createScheduler.cancelled")
        DokoLogging.shared.postLoggingResponse(.schedulers(".cancelled"))
      }
      await withTaskGroup(of: Void.self) { group in
        self.logger.debug("\(timestamp()) SE.createScheduler\(schedules.description)")
        DokoLogging.shared.postLoggingResponse(.schedulers("\(schedules.description)"))
        for schedule in schedules {
          let packet = schedule.packetType
          switch schedule.schedulerType {
          case .oneShot:
            group.addTask {
              await DokoPacketManager.shared.appendDokoPacket(packet)
              DokoLogging.shared.postLoggingResponse(.schedulers("firing: \(packet.description)"))
            }

          case .oneShotWithDelay(let seconds):
            group.addTask {
              do {
                try await Task.sleep(for: .seconds(seconds))
              } catch { return }
              guard !Task.isCancelled else { return }
              await DokoPacketManager.shared.appendDokoPacket(packet)
              DokoLogging.shared.postLoggingResponse(.schedulers("firing: \(packet.description)"))
            }

          case .firesThenDelays(let seconds):
            group.addTask {
              while !Task.isCancelled {
                do {
                  await DokoPacketManager.shared.appendDokoPacket(packet)
                  DokoLogging.shared.postLoggingResponse(.schedulers("firing: \(packet.description)"))
                  try await Task.sleep(for: .seconds(seconds))
                } catch { return }
                guard !Task.isCancelled else { return }
              }
            }

          case .delaysThenFires(let seconds):
            group.addTask {
              while !Task.isCancelled {
                do {
                  try await Task.sleep(for: .seconds(seconds))
                } catch { return }
                guard !Task.isCancelled else { return }
                await DokoPacketManager.shared.appendDokoPacket(packet)
                DokoLogging.shared.postLoggingResponse(.schedulers("firing: \(packet.description)"))
              }
            }
          }
        }

        for await _ in group { }
      }
      self.logger.debug("\(timestamp()) SE.createScheduler.task killed")
      DokoLogging.shared.postLoggingResponse(.schedulers("scheduler task killed"))
    }
  }
}
